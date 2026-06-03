--  Operation-Based (CmRDT) sync engine.
--  Replicas broadcast granular, immutable mutation events.
--  Downstream operations must be applied exactly once.
--
--  Network trait: Hyper-low bandwidth consumption, ideal for
--  ordered delivery channels (WebSockets, TCP/TLS streams).
with CRDT.Core;

package CRDT.Sync.Op_Based is

   --  Kind of operation for discriminated record.
   type Op_Kind is (Op_Insert, Op_Delete, Op_Increment, Op_Decrement);

   --  A single mutation operation for replication.
   --  @field Seq      Monotonic sequence number.
   --  @field Node     Replica that generated this operation.
   --  @field Kind     Discriminant: which variant is active.
   --  @field Position Insertion position (for Op_Insert).
   --  @field Del_Position  Deletion position (for Op_Delete).
   --  @field Amount   Increment/decrement amount.
   --  @field Actor    Target replica for counter ops.
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
   --  @param Log  Operation log to append to.
   --  @param Op   Operation to record.
   procedure Append (Log : in out Op_Log; Op : Operation);

   --  Number of unacknowledged operations.
   --  @return Count of operations not yet acknowledged.
   function Size (Log : Op_Log) return Natural;

   --  Get operation at index (1-based, excluding GC'd).
   --  @param Log    Operation log to query.
   --  @param Index  1-based index.
   --  @return Operation at that index.
   function Get (Log : Op_Log; Index : Positive) return Operation;

   --  Mark operations up to Seq as acknowledged (ready for GC).
   --  @param Log       Operation log to modify.
   --  @param Up_To_Seq  Acknowledge all operations with Seq <= this.
   procedure Acknowledge (Log : in out Op_Log; Up_To_Seq : Natural);

   --  Compact the log, physically removing acknowledged operations.
   --  @param Log  Operation log to compact.
   procedure Compact (Log : in out Op_Log);

private

   type Op_Array is array (Positive range <>) of Operation;

   type Op_Log (Capacity : Positive) is record
      Ops   : Op_Array (1 .. Capacity);
      Count : Natural := 0;
      GC    : Natural := 0;
   end record;

end CRDT.Sync.Op_Based;
