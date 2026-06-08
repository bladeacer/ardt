--  Core types and utilities used across all CRDT packages.
--  Provides replica identification, Lamport/HLC timestamps,
--  vector clocks, and the wire protocol version constant.
--  
--  Requirements traceability:
--  - HLR-CORE-TS: Timestamp types and operations for causal ordering
--  - HLR-CORE-VC: Vector clock operations for distributed state tracking
--  - HLR-CORE-PROTO: Wire protocol version management
with Ada.Calendar;

package CRDT.Core with
  SPARK_Mode
is

   use Ada.Calendar;

   --  Unique identifier for a replica in the distributed system.
   type Replica_Id is new Positive;

   --  Lamport timestamp for causal ordering.
   --  Ordered by logical counter first, then node ID for tie-breaking.
   --  Unlike wall-clock timestamps, Lamport timestamps preserve causality
   --  even when physical clocks drift across replicas.
   --  @field Stamp  Logical counter, incremented on each local event.
   --  @field Node   Replica that generated this timestamp.
   type Lamport_Time is record
      Stamp : Natural := 0;
      Node  : Replica_Id := 1;
   end record;

   --  Lamport less-than: compares Stamp first, then Node.
   --  @param Left   Left operand.
   --  @param Right  Right operand.
   --  @return True if Left causally precedes Right.
   function "<" (Left, Right : Lamport_Time) return Boolean with
     Post => ("<"'Result =
               (if Left.Stamp < Right.Stamp then True
                elsif Left.Stamp > Right.Stamp then False
                else Left.Node < Right.Node));

   --  Lamport equality: both Stamp and Node must match.
   --  @param Left   Left operand.
   --  @param Right  Right operand.
   --  @return True if timestamps are identical.
   function "=" (Left, Right : Lamport_Time) return Boolean with
     Post => ("="'Result = (Left.Stamp = Right.Stamp
                            and then Left.Node = Right.Node));

   --  Lamport greater-than: inverse of "<".
   --  @param Left   Left operand.
   --  @param Right  Right operand.
   --  @return True if Left causally follows Right.
   function ">" (Left, Right : Lamport_Time) return Boolean with
     Post => (">"'Result = (not (Left < Right)
                            and then not (Left = Right)));

   --  Return the maximum of two Lamport timestamps.
   --  @param Left   First timestamp.
   --  @param Right  Second timestamp.
   --  @return The causally later timestamp.
   function Lamport_Max (Left, Right : Lamport_Time) return Lamport_Time with
     Post => (if Left > Right then Lamport_Max'Result = Left
              else Lamport_Max'Result = Right);

   --  Hybrid Logical Clock timestamp combining physical wall clock
   --  with a logical component for causality across clock-skewed nodes.
   --  @field Wall  Physical wall-clock time.
   --  @field Node  Replica that generated this timestamp.
   --  @field Log   Logical component, climbs past max(physical, logical).
   type HLC_Time is record
      Wall : Ada.Calendar.Time;
      Node : Replica_Id;
      Log  : Natural := 0;
   end record;

   --  HLC less-than: compares Wall, then Log, then Node.
   --  @param Left   Left HLC timestamp.
   --  @param Right  Right HLC timestamp.
   --  @return True if Left causally precedes Right.
   function HLC_Less (Left, Right : HLC_Time) return Boolean with
     Post => (HLC_Less'Result =
               (if Left.Wall < Right.Wall then True
                elsif Left.Wall > Right.Wall then False
                elsif Left.Log < Right.Log then True
                elsif Left.Log > Right.Log then False
                else Left.Node < Right.Node));

   --  HLC equality: all three fields must match.
   --  @param Left   Left HLC timestamp.
   --  @param Right  Right HLC timestamp.
   --  @return True if timestamps are identical.
   function HLC_Eq (Left, Right : HLC_Time) return Boolean with
     Post => (HLC_Eq'Result =
               (Left.Wall = Right.Wall
                and then Left.Log = Right.Log
                and then Left.Node = Right.Node));

   --  Return the maximum of two HLC timestamps.
   --  @param Left   First HLC timestamp.
   --  @param Right  Second HLC timestamp.
   --  @return The causally later timestamp.
   function HLC_Max (Left, Right : HLC_Time) return HLC_Time with
     Post => (if HLC_Less (Left, Right) then HLC_Max'Result = Right
              else HLC_Max'Result = Left);

   --  Vector clock for tracking per-replica event counts.
   --  Index 1 corresponds to the first replica seen.
   type VTime is array (Positive range <>) of Natural with
     Default_Component_Value => 0;

   --  Strict vector-clock less-than: all entries <= and at least one <.
   --  @param Left   Left vector clock.
   --  @param Right  Right vector clock.
   --  @return True if Left is strictly behind Right.
   function VTime_Less (Left, Right : VTime) return Boolean with
     Pre  => Left'Length = Right'Length and then Left'First = Right'First,
     Post => VTime_Less'Result =
               (not VTime_Eq (Left, Right)
                and then (for all I in Left'Range => Left (I) <= Right (I)));

   --  Non-strict vector-clock less-or-equal: all entries <=.
   --  @param Left   Left vector clock.
   --  @param Right  Right vector clock.
   --  @return True if Left is at or behind Right.
   function VTime_Leq (Left, Right : VTime) return Boolean with
     Pre  => Left'Length = Right'Length and then Left'First = Right'First,
     Post => VTime_Leq'Result =
               (for all I in Left'Range => Left (I) <= Right (I));

   --  Vector-clock equality: all entries match.
   --  @param Left   Left vector clock.
   --  @param Right  Right vector clock.
   --  @return True if Left and Right are identical.
   function VTime_Eq (Left, Right : VTime) return Boolean with
     Pre  => Left'Length = Right'Length and then Left'First = Right'First,
     Post => VTime_Eq'Result =
               (for all I in Left'Range => Left (I) = Right (I));

   --  Element-wise max merge of Source into Target.
   --  @param Target  Vector clock to update.
   --  @param Source  Vector clock to merge from.
   procedure VTime_Merge (Target : in out VTime; Source : VTime) with
     Pre  => Target'Length = Source'Length
             and then Target'First = Source'First,
     Post => (for all I in Target'Range =>
                (if Source (I) > Target'Old (I)
                 then Target (I) = Source (I)
                 else Target (I) = Target'Old (I)))
             and then VTime_Leq (Source, Target)
             and then VTime_Leq (Target'Old, Target);

   --  Increment entry Idx by one.
   --  @param VT   Vector clock to modify.
   --  @param Idx  Index of the entry to increment.
   procedure VTime_Increment (VT : in out VTime; Idx : Positive) with
     Pre  => Idx in VT'Range and then VT (Idx) < Natural'Last,
     Post => VT (Idx) = VT'Old (Idx) + 1
             and then (for all I in VT'Range =>
                         (if I /= Idx then VT (I) = VT'Old (I)));

   --  Generate a new globally unique replica identifier.
   --  Uses a cryptographically seeded random generator.
   --  @return A fresh Replica_Id not previously returned.
   function New_Replica_Id return Replica_Id with
     SPARK_Mode => Off;

   --  Wire protocol version for all serialized CRDT state.
   --  Increment when making breaking changes to the binary format.
   Protocol_Version : constant Natural := 2;

end CRDT.Core;
