--  Hybrid Logical Clock (HLC) implementation.
--  Combines physical wall-clock time with a logical counter
--  to ensure causality is preserved even when physical clocks drift.
--
--  Usage:
--     Clock : HLC.Instance := HLC.Create (Node => 1);
--     HLC.Tick (Clock);           --  before sending
--     HLC.Recv (Clock, Remote);   --  on receiving remote timestamp
--     TS : constant HLC_Time := HLC.Now (Clock);
with Ada.Calendar;
with Ada_CRDT.Core;

package Ada_CRDT.HLC is

   type HLC_Time is new Core.HLC_Time;

   type Instance is private;

   function Create (Node : Core.Replica_Id) return Instance;

   --  Advance the local clock. Call before attaching a timestamp
   --  to an outgoing message or event.
   procedure Tick (Clock : in out Instance);

   --  Merge with a received remote timestamp.
   --  Ensures the local clock always advances past the received value,
   --  preserving causal ordering across replicas.
   procedure Recv (Clock : in out Instance; Remote : HLC_Time);

   function Now (Clock : Instance) return HLC_Time;

   function "<" (Left, Right : HLC_Time) return Boolean;
   function "=" (Left, Right : HLC_Time) return Boolean;
   function ">" (Left, Right : HLC_Time) return Boolean;

private

   type Instance is record
      Wall : Ada.Calendar.Time;
      Node : Core.Replica_Id;
      Log  : Natural := 0;
   end record;

   function Now (Clock : Instance) return HLC_Time is
     (HLC_Time'(Wall => Clock.Wall,
                Node => Clock.Node,
                Log  => Clock.Log));

end Ada_CRDT.HLC;
