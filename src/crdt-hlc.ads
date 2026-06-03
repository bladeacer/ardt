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
with CRDT.Core;

package CRDT.HLC is

   --  HLC timestamp wrapping Core's HLC_Time.
   type HLC_Time is new Core.HLC_Time;

   --  HLC clock instance tracking physical time and logical component.
   type Instance is private;

   --  Create a new HLC instance for the given node.
   --  @param Node  Replica identifier.
   --  @return  Initialized HLC clock.
   function Create (Node : Core.Replica_Id) return Instance;

   --  Advance the local clock. Call before attaching a timestamp
   --  to an outgoing message or event.
   --  @param Clock  HLC instance to tick.
   procedure Tick (Clock : in out Instance);

   --  Merge with a received remote timestamp.
   --  Ensures the local clock always advances past the received value,
   --  preserving causal ordering across replicas.
   --  @param Clock   Local HLC instance.
   --  @param Remote  Timestamp received from a remote peer.
   procedure Recv (Clock : in out Instance; Remote : HLC_Time);

   --  Read the current HLC timestamp.
   --  @param Clock  HLC instance to query.
   --  @return  Current HLC timestamp.
   function Now (Clock : Instance) return HLC_Time;

   --  HLC less-than: compares Wall, then Log, then Node.
   --  @param Left   Left HLC timestamp.
   --  @param Right  Right HLC timestamp.
   --  @return True if Left causally precedes Right.
   function "<" (Left, Right : HLC_Time) return Boolean;

   --  HLC equality: all three fields must match.
   --  @param Left   Left HLC timestamp.
   --  @param Right  Right HLC timestamp.
   --  @return True if timestamps are identical.
   function "=" (Left, Right : HLC_Time) return Boolean;

   --  HLC greater-than: inverse of "<".
   --  @param Left   Left HLC timestamp.
   --  @param Right  Right HLC timestamp.
   --  @return True if Left causally follows Right.
   function ">" (Left, Right : HLC_Time) return Boolean;

private

   type Instance is record
      Wall : Ada.Calendar.Time;
      Node : Core.Replica_Id;
      Log  : Natural := 0;
   end record;

   --  Expression function for efficient Now access.
   function Now (Clock : Instance) return HLC_Time is
     (HLC_Time'(Wall => Clock.Wall,
                 Node => Clock.Node,
                 Log  => Clock.Log));

end CRDT.HLC;
