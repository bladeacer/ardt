with Ada_CRDT.Core;

package Ada_CRDT.Sync.Op_Based is

   -- Operation-based (CmRDT) sync engine.
   -- Replicas broadcast granular mutation events.
   -- Downstream operations must be applied exactly once.

   -- Operation log entry
   type Op_Kind is (Op_Insert, Op_Delete, Op_Increment, Op_Decrement);

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

   -- Operation log with bounded capacity
   type Op_Log (Capacity : Positive) is private;

   -- Append an operation to the log
   procedure Append (Log : in out Op_Log; Op : Operation);

   -- How many ops stored
   function Size (Log : Op_Log) return Natural;

   -- Get operation at index
   function Get (Log : Op_Log; Index : Positive) return Operation;

   -- Acknowledge ops up to a given sequence number (for GC)
   procedure Acknowledge (Log : in out Op_Log; Up_To_Seq : Natural);

   -- Garbage collect acknowledged ops
   procedure Compact (Log : in out Op_Log);

private

   type Op_Array is array (Positive range <>) of Operation;

   type Op_Log (Capacity : Positive) is record
      Ops   : Op_Array (1 .. Capacity);
      Count : Natural := 0;
      GC    : Natural := 0;
   end record;

end Ada_CRDT.Sync.Op_Based;
