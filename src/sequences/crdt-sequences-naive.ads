--  Naive per-element RGA engine.
--  Every single element is its own individually allocated node.
--  Useful for: educational baselines, chaotic editing environments,
--  or small sequences where per-element overhead is acceptable.
--
--  @formal Element_Type  The type of elements stored in the sequence.
--  @formal Max_Items     Maximum number of nodes.
with Ada.Streams;
with CRDT.Core;

generic
   type Element_Type is private;
   Max_Items   : Positive;
package CRDT.Sequences.Naive with
  SPARK_Mode
is

   --  Unique identifier for a node in the sequence.
   --  @field Replica  Replica that created this node.
   --  @field Seq      Per-replica sequence number.
   type Node_Id is record
      Replica : Core.Replica_Id;
      Seq     : Natural;
   end record;

   type Element_Array is array (Positive range <>) of Element_Type;

   --  Bounded Naive RGA with pre-allocated node capacity.
   type RGA (Capacity : Positive) is private;

   --  Standard Ada iterator support
   type Cursor is private;

   --  Check if cursor points to a valid element.
   --  @param Position  Cursor to check.
   --  @return True if the cursor is not at the end.
   function Has_Element (Position : Cursor) return Boolean;

   --  Check if cursor is valid within a specific container.
   --  @param Container  The sequence container.
   --  @param Position   Cursor to check.
   --  @return True if the cursor is within bounds.
   function Has_Element (Container : RGA; Position : Cursor) return Boolean;

   --  Return cursor to the first visible element.
   --  @param Container  The sequence container.
   --  @return Cursor positioned at first element.
   function First (Container : RGA) return Cursor;

   --  Advance cursor to the next visible element.
   --  @param Container  The sequence container.
   --  @param Position  Cursor to advance (modified in place).
   procedure Next (Container : RGA; Position : in out Cursor);

   --  Read element at cursor position.
   --  @param Container  The sequence container.
   --  @param Position   Cursor to read from.
   --  @return Element at the cursor's position.
   function Element (Container : RGA; Position : Cursor) return Element_Type;

   --  Number of internal storage items (linked list nodes).
   --  @param R  The sequence to examine.
   --  @return Count of allocated nodes (includes tombstones).
   function Count (R : RGA) return Natural;

   --  Total visible elements (excluding tombstones).
   --  @param R  The sequence to examine.
   --  @return Number of non-deleted elements.
   function Size (R : RGA) return Natural;

   --  Alias for Size.
   --  @param R  The sequence to examine.
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
   --  @param Id      Unique node identifier (used for first element).
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
   --  @param Left   Left sequence operand.
   --  @param Right  Right sequence operand.
   --  @return True if both sequences are identical.
   function "=" (Left, Right : RGA) return Boolean;

   --  Physically remove all tombstoned items, reclaiming slots.
   --  @param R  The sequence to compact.
   procedure Compact (R : in out RGA);

   --  Serialize the RGA to a stream.
   --  @param Stream  Output stream.
   --  @param Item    RGA to serialize.
   procedure Write_RGA
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Item   : RGA);

   --  Deserialize the RGA from a stream.
   --  @param Stream  Input stream.
   --  @param Item    Deserialized RGA.
   procedure Read_RGA
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Item   : out RGA);

private

   type RGA_Item is record
      Id      : Node_Id;
      Value   : Element_Type;
      Deleted : Boolean := False;
      Next    : Natural := 0;
   end record;

   type Item_Array is array (Positive range <>) of RGA_Item;

   type Cursor is record
      Total : Natural := 0;
      Pos   : Natural := 0;
   end record;

   type RGA (Capacity : Positive) is record
      Items   : Item_Array (1 .. Capacity);
      Head    : Natural := 0;
      Count   : Natural := 0;
      Free    : Natural := 0;
      Total   : Natural := 0;
   end record;

   for RGA'Write use Write_RGA;
   for RGA'Read  use Read_RGA;

end CRDT.Sequences.Naive;
