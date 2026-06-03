--  Core types and utilities used across all CRDT packages.
--  Provides replica identification, Lamport/HLC timestamps,
--  vector clocks, and the wire protocol version constant.
with Ada.Calendar;

package CRDT.Core is

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
   --  @return True if Left causally precedes Right.
   function "<" (Left, Right : Lamport_Time) return Boolean;

   --  Lamport equality: both Stamp and Node must match.
   --  @return True if timestamps are identical.
   function "=" (Left, Right : Lamport_Time) return Boolean;

   --  Lamport greater-than: inverse of "<".
   --  @return True if Left causally follows Right.
   function ">" (Left, Right : Lamport_Time) return Boolean;

   --  Return the maximum of two Lamport timestamps.
   --  @return The causally later timestamp.
   function Lamport_Max (Left, Right : Lamport_Time) return Lamport_Time;

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
   --  @return True if Left causally precedes Right.
   function HLC_Less (Left, Right : HLC_Time) return Boolean;

   --  HLC equality: all three fields must match.
   --  @return True if timestamps are identical.
   function HLC_Eq   (Left, Right : HLC_Time) return Boolean;

   --  Return the maximum of two HLC timestamps.
   --  @return The causally later timestamp.
   function HLC_Max  (Left, Right : HLC_Time) return HLC_Time;

   --  Vector clock for tracking per-replica event counts.
   --  Index 1 corresponds to the first replica seen.
   --  @field Indexed by replica slot, each element is the event count.
   type VTime is array (Positive range <>) of Natural with
     Default_Component_Value => 0;

   --  Strict vector-clock less-than: all entries <= and at least one <.
   --  @return True if Left is strictly behind Right.
   function VTime_Less (Left, Right : VTime) return Boolean;

   --  Non-strict vector-clock less-or-equal: all entries <=.
   --  @return True if Left is at or behind Right.
   function VTime_Leq  (Left, Right : VTime) return Boolean;

   --  Vector-clock equality: all entries match.
   --  @return True if Left and Right are identical.
   function VTime_Eq   (Left, Right : VTime) return Boolean;

   --  Element-wise max merge of Source into Target.
   --  @param Target  Vector clock to update.
   --  @param Source  Vector clock to merge from.
   procedure VTime_Merge (Target : in out VTime; Source : VTime);

   --  Increment entry Idx by one.
   --  @param VT   Vector clock to modify.
   --  @param Idx  Index of the entry to increment.
   procedure VTime_Increment (VT : in out VTime; Idx : Positive);

   --  Generate a new globally unique replica identifier.
   --  Uses a cryptographically seeded random generator.
   --  @return A fresh Replica_Id not previously returned.
   function New_Replica_Id return Replica_Id;

   --  Wire protocol version for all serialized CRDT state.
   --  Increment when making breaking changes to the binary format.
   Protocol_Version : constant Natural := 2;

private

   Generator_Init : Boolean := False;

end CRDT.Core;
