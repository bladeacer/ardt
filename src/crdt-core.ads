--  Core types and utilities used across all CRDT packages.
--  Provides replica identification, Lamport/HLC timestamps,
--  vector clocks, and the wire protocol version constant.
with Ada.Calendar;

package CRDT.Core is

   type Replica_Id is new Positive;

   --  Lamport timestamp for causal ordering.
   --  Ordered by logical counter first, then node ID for tie-breaking.
   --  Unlike wall-clock timestamps, Lamport timestamps preserve causality
   --  even when physical clocks drift across replicas.
   type Lamport_Time is record
      Stamp : Natural := 0;
      Node  : Replica_Id := 1;
   end record;

   function "<" (Left, Right : Lamport_Time) return Boolean;
   function "=" (Left, Right : Lamport_Time) return Boolean;
   function ">" (Left, Right : Lamport_Time) return Boolean;
   function Lamport_Max (Left, Right : Lamport_Time) return Lamport_Time;

   --  Hybrid Logical Clock timestamp combining physical wall clock
   --  with a logical component for causality across clock-skewed nodes.
   type HLC_Time is record
      Wall : Ada.Calendar.Time;
      Node : Replica_Id;
      Log  : Natural := 0;
   end record;

   function HLC_Less (Left, Right : HLC_Time) return Boolean;
   function HLC_Eq   (Left, Right : HLC_Time) return Boolean;
   function HLC_Max  (Left, Right : HLC_Time) return HLC_Time;

   --  Vector clock for tracking per-replica event counts.
   type VTime is array (Positive range <>) of Natural with
     Default_Component_Value => 0;

   function VTime_Less (Left, Right : VTime) return Boolean;
   function VTime_Leq  (Left, Right : VTime) return Boolean;
   function VTime_Eq   (Left, Right : VTime) return Boolean;
   procedure VTime_Merge (Target : in out VTime; Source : VTime);
   procedure VTime_Increment (VT : in out VTime; Idx : Positive);

   function New_Replica_Id return Replica_Id;

   --  Wire protocol version for all serialized CRDT state.
   --  Increment when making breaking changes to the binary format.
   Protocol_Version : constant Natural := 2;

private

   Generator_Init : Boolean := False;

end CRDT.Core;
