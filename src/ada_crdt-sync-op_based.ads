--  Operation-Based (CmRDT) sync engine.
--  Replicas broadcast granular, immutable mutation events.
--  Downstream operations must be applied exactly once.
--
--  Network trait: Hyper-low bandwidth consumption, ideal for
--  ordered delivery channels (WebSockets, TCP/TLS streams).
with Ada_CRDT.Core;

package Ada_CRDT.Sync.Op_Based is

   type Op_Kind is (Op_Insert, Op_Delete, Op_Increment, Op_Decrement);

   --  A single mutation operation for replication.
   type Operation (Kind : Op_Kind := Op_Insert) is record
      Seq     : Natural;
      Node    : Core.Replica_Id;
      case Kind is
         when Op_Insert =>
            Position : Positive;
         when Op_Delete =>
            Del_Position : Positive;
         when Op_Increment | Op_Decrement =>
            Amount    : Natural;
            Actor     : Core.Replica_Id;
      end case;
   end record;

   --  Bounded operation log for buffering outgoing operations.
   type Op_Log (Capacity : Positive) is private;

   --  Append an operation to the log.
   procedure Append (Log : in out Op_Log; Op : Operation);

   --  Number of unacknowledged operations.
   function Size (Log : Op_Log) return Natural;

   --  Get operation at index (1-based, excluding GC'd).
   function Get (Log : Op_Log; Index : Positive) return Operation;

   --  Mark operations up to Seq as acknowledged (ready for GC).
   procedure Acknowledge (Log : in out Op_Log; Up_To_Seq : Natural);

   --  Compact the log, physically removing acknowledged operations.
   procedure Compact (Log : in out Op_Log);

private

   type Op_Array is array (Positive range <>) of Operation;

   type Op_Log (Capacity : Positive) is record
      Ops   : Op_Array (1 .. Capacity);
      Count : Natural := 0;
      GC    : Natural := 0;
   end record;

end Ada_CRDT.Sync.Op_Based;
