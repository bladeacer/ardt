--  Yjs-style splitting block RGA engine.
--  Groups contiguous characters written by the same client into
--  memory blocks (size Max_Stride). Structural splitting splits
--  a block when an insert targets its middle, then stitches the
--  new block in between.
--
--  Uses a pre-allocated contiguous array of blocks (memory arena)
--  to avoid heap fragmentation.
--
--  Industry equivalence: Yjs YATA algorithm.
with Ada.Streams;
with Ada_CRDT.Core;

generic
   type Element_Type is private;
   Max_Items    : Positive;
   Max_Stride   : Positive := 64;
   Max_Replicas : Positive := 32;
package Ada_CRDT.Sequences.Yjs with
  SPARK_Mode
is

   type Node_Id is record
      Replica : Core.Replica_Id;
      Seq     : Natural;
   end record;

   type Element_Array is array (Positive range <>) of Element_Type;

   type RGA (Item_Capacity : Positive) is private;

   --  Standard Ada iterator support
   --  Usage:
   --    Pos := First (R);
   --    while Has_Element (R, Pos) loop
   --       E := Element (R, Pos);
   --       Next (R, Pos);
   --    end loop;

   type Cursor is private;

   function Has_Element (Position : Cursor) return Boolean;
   function Has_Element (Container : RGA; Position : Cursor) return Boolean;
   function First (Container : RGA) return Cursor;
   procedure Next (Container : RGA; Position : in out Cursor);
   function Element (Container : RGA; Position : Cursor) return Element_Type;

   --  Number of internal storage items (linked list nodes).
   function Count (R : RGA) return Natural;

   --  Total visible + tombstoned elements.
   function Size (R : RGA) return Natural;

   function Length (R : RGA) return Natural is (Size (R));

   --  Get element at physical position (1-indexed).
   function Get (R : RGA; Pos : Positive) return Element_Type;

   --  Insert single element at physical position.
   procedure Insert (R     : in out RGA;
                     Pos   : Positive;
                     Id    : Node_Id;
                     Value : Element_Type);

   --  Insert multiple contiguous elements as a single Item block.
   procedure Insert_Bulk (R      : in out RGA;
                          Pos    : Positive;
                          Id     : Node_Id;
                          Values : Element_Array);

   --  Tombstone-delete element at physical position.
   procedure Delete (R   : in out RGA;
                     Pos : Positive);

   --  Tombstone-delete the item with the given Node_Id.
   procedure Delete_Node (R : in out RGA; Id : Node_Id);

   --  Convergent merge: insert all Source items not in Target,
   --  preserving causal order by Node_Id.
   procedure Merge (Target : in out RGA;
                    Source : RGA);

   function "=" (Left, Right : RGA) return Boolean;

   --  State Vector / Delta Sync

   type Replica_Max_Seq is record
      Replica : Core.Replica_Id;
      Max_Seq : Natural;
   end record;

   type Replica_Max_Seq_Array is array (Positive range <>) of Replica_Max_Seq;

   procedure Compute_State_Vector
     (R     : RGA;
      SV    : out Replica_Max_Seq_Array;
      Count : out Natural);

   procedure Sync_Delta
     (Target    : in out RGA;
      Source    : RGA;
      Remote_SV : Replica_Max_Seq_Array;
      SV_Count  : Natural);

   --  Tombstone Garbage Collection

   --  Physically remove all tombstoned items, reclaiming slots.
   procedure Compact (R : in out RGA);

   --  Stream Serialization with Protocol Version
   --
   --  Wire format: [Protocol_Version : Natural] [Total : Natural]
   --    [Num_Items : Natural] [Item ...]
   --  Each Item: [Node_Id] [Len : Natural] [Deleted : Boolean]
   --    [Content : Element_Type array of length Len]

   procedure Write_RGA
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Item   : RGA);

   procedure Read_RGA
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
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

   type Cursor is record
      Total : Natural := 0;
      Pos   : Natural := 0;
   end record;

   type RGA (Item_Capacity : Positive) is record
      Items   : Item_Array (1 .. Item_Capacity);
      Head    : Natural := 0;
      Count   : Natural := 0;
      Free    : Natural := 0;
      Total   : Natural := 0;
   end record;

   for RGA'Write use Write_RGA;
   for RGA'Read  use Read_RGA;

end Ada_CRDT.Sequences.Yjs;
