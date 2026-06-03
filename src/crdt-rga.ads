--  Replicated Growable Array (RGA) — default Yjs-style chunk-based engine.
--  Contiguous elements written by the same replica are stored in sized
--  blocks (Max_Stride), dramatically reducing allocation overhead
--  vs. per-character nodes. Default sequence engine for CRDT.
--
--  Industry equivalence: Yjs/YATA algorithm.
--  Supports structural splitting, state vector delta sync,
--  tombstone garbage collection, and protocol-versioned serialization.
--
--  @formal Element_Type  The type of elements stored in the sequence.
--  @formal Max_Items     Maximum number of internal linked-list nodes.
--  @formal Max_Stride    Maximum block size for contiguous elements.
--  @formal Max_Replicas  Maximum distinct replicas for delta sync.
with Ada.Streams;
with CRDT.Core;

generic
   type Element_Type is private;
   Max_Items    : Positive;
   Max_Stride   : Positive := 64;
   Max_Replicas : Positive := 32;
package CRDT.Rga with
  SPARK_Mode
is

   --  Unique identifier for a node in the sequence.
   --  @field Replica  Replica that created this node.
   --  @field Seq      Per-replica sequence number.
   type Node_Id is record
      Replica : Core.Replica_Id;
      Seq     : Natural;
   end record;

   --  Array of elements for bulk insert operations.
   type Element_Array is array (Positive range <>) of Element_Type;

   --  Bounded RGA sequence with pre-allocated item capacity.
   type RGA (Item_Capacity : Positive) is private;

   --  Number of internal storage items (linked list nodes).
   --  @return Count of allocated nodes (includes tombstones).
   function Count (R : RGA) return Natural;

   --  Total visible elements (excluding tombstones).
   --  @return Number of non-deleted elements.
   function Size (R : RGA) return Natural;

   --  Alias for Size.
   --  @return Number of non-deleted elements.
   function Length (R : RGA) return Natural is (Size (R));

   --  Get element at physical position (1-indexed).
   --  @param R    The sequence.
   --  @param Pos  1-based position.
   --  @return Element at that position.
   function Get (R : RGA; Pos : Positive) return Element_Type;

   --  Insert single element at physical position.
   --  @param R      The sequence to modify.
   --  @param Pos    1-based insertion position.
   --  @param Id     Unique node identifier for this element.
   --  @param Value  Element to insert.
   procedure Insert (R     : in out RGA;
                     Pos   : Positive;
                     Id    : Node_Id;
                     Value : Element_Type);

   --  Insert multiple contiguous elements as a single Item block.
   --  @param R       The sequence to modify.
   --  @param Pos     1-based insertion position.
   --  @param Id      Unique node identifier (used for the first element).
   --  @param Values  Array of elements to insert contiguously.
   procedure Insert_Bulk (R      : in out RGA;
                           Pos    : Positive;
                           Id     : Node_Id;
                           Values : Element_Array);

   --  Tombstone-delete element at physical position.
   --  @param R    The sequence to modify.
   --  @param Pos  1-based position of element to delete.
   procedure Delete (R   : in out RGA;
                     Pos : Positive);

   --  Tombstone-delete the item with the given Node_Id.
   --  @param R   The sequence to modify.
   --  @param Id  Node identifier of the item to delete.
   procedure Delete_Node (R : in out RGA; Id : Node_Id);

   --  Convergent merge: insert all Source items not in Target,
   --  preserving causal order by Node_Id.
   --  @param Target  The sequence to merge into.
   --  @param Source  The sequence to merge from.
   procedure Merge (Target : in out RGA;
                     Source : RGA);

   --  Structural equality: same Node_Id, content, and deletion status.
   --  @return True if both sequences are identical.
   function "=" (Left, Right : RGA) return Boolean;

   --  State Vector / Delta Sync

   --  Per-replica maximum sequence number.
   --  @field Replica  Replica identifier.
   --  @field Max_Seq  Highest sequence number seen from this replica.
   type Replica_Max_Seq is record
      Replica : Core.Replica_Id;
      Max_Seq : Natural;
   end record;

   --  Array of per-replica max-sequence entries.
   type Replica_Max_Seq_Array is array (Positive range <>) of Replica_Max_Seq;

   --  Compute state vector: max seq per replica for delta sync.
   --  @param R      The sequence to analyze.
   --  @param SV     Output array of per-replica max seq values.
   --  @param Count  Number of entries written to SV.
   procedure Compute_State_Vector
     (R     : RGA;
      SV    : out Replica_Max_Seq_Array;
      Count : out Natural);

   --  Delta-sync: merge only items newer than remote state vector.
   --  @param Target    The sequence to merge into.
   --  @param Source    The sequence to merge from.
   --  @param Remote_SV State vector of the remote peer.
   --  @param SV_Count  Number of entries in Remote_SV.
   procedure Sync_Delta
     (Target    : in out RGA;
      Source    : RGA;
      Remote_SV : Replica_Max_Seq_Array;
      SV_Count  : Natural);

   --  Tombstone Garbage Collection

   --  Physically remove all tombstoned items, reclaiming slots.
   --  @param R  The sequence to compact.
   procedure Compact (R : in out RGA);

   --  Stream Serialization with Protocol Version
   --
   --  Wire format: [Protocol_Version : Natural] [Total : Natural]
   --    [Num_Items : Natural] [Item ...]
   --  Each Item: [Node_Id] [Len : Natural] [Deleted : Boolean]
   --    [Content : Element_Type array of length Len]

   --  Serialize the RGA to a stream.
   --  @param Stream  Output stream.
   --  @param Item    RGA to serialize.
   procedure Write_RGA (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
                        Item   : RGA);

   --  Deserialize the RGA from a stream.
   --  @param Stream  Input stream.
   --  @param Item    Deserialized RGA.
   procedure Read_RGA  (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
                        Item   : out RGA);

private

   type Element_Store is array (1 .. Max_Stride) of Element_Type;

   type RGA_Item is record
      Id      : Node_Id;
      Content : Element_Store;
      Len     : Natural := 0;
      Deleted : Boolean := False;
      Next    : Natural := 0;
   end record;

   type Item_Array is array (Positive range <>) of RGA_Item;

   type RGA (Item_Capacity : Positive) is record
      Items   : Item_Array (1 .. Item_Capacity);
      Head    : Natural := 0;
      Count   : Natural := 0;
      Free    : Natural := 0;
      Total   : Natural := 0;
   end record;

   for RGA'Write use Write_RGA;
   for RGA'Read  use Read_RGA;

end CRDT.Rga;
