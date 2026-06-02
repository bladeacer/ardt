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

   type Cursor is private;

   function Has_Element (Position : Cursor) return Boolean;

   type Constant_Reference_Type (Element : not null access constant Element_Type) is private;

   type RGA (Item_Capacity : Positive) is private;

   -- Count of items in the linked list
   function Count (R : RGA) return Natural;

   -- Total elements across all items (including tombstones)
   function Size (R : RGA) return Natural;

   function Length (R : RGA) return Natural is (Size (R));

   -- Get element at physical position (1-indexed item element position)
   function Get (R : RGA; Pos : Positive) return Element_Type;

   -- Insert single element at physical position
   procedure Insert (R     : in out RGA;
                     Pos   : Positive;
                     Id    : Node_Id;
                     Value : Element_Type);

   -- Insert multiple contiguous elements as a single Item block
   procedure Insert_Bulk (R      : in out RGA;
                           Pos    : Positive;
                           Id     : Node_Id;
                           Values : Element_Array);

   -- Delete element at physical position (tombstone)
   procedure Delete (R   : in out RGA;
                     Pos : Positive);

   -- Delete item starting with the given Node_Id
   procedure Delete_Node (R : in out RGA; Id : Node_Id);

   -- Merge all source items into target
   procedure Merge (Target : in out RGA;
                    Source : RGA);

   function "=" (Left, Right : RGA) return Boolean;

   -- === State Vector / Delta Sync ===

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

   -- === Tombstone Garbage Collection ===

   procedure Compact (R : in out RGA);

   -- === Stream Serialization with Protocol Version ===

   -- Wire format: [Protocol_Version : Natural] [Total : Natural]
   --   [Num_Items : Natural] [Item ...]
   -- Each Item: [Node_Id] [Len : Natural] [Deleted : Boolean]
   --   [Content : Element_Type array of length Len]

   procedure Write_RGA (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
                         Item   : RGA);

   procedure Read_RGA  (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
                         Item   : out RGA);

   function Iterate (Container : aliased RGA) return Cursor;

   function Constant_Ref (Container : aliased in RGA; Position : Cursor)
      return Constant_Reference_Type;

   procedure Next (Position : in out Cursor);

private

   type Cursor is record
      Container : access constant RGA;
      Pos       : Natural := 0;
   end record;

   type Constant_Reference_Type (Element : not null access constant Element_Type) is
      null record;

   type Element_Store is array (1 .. Max_Stride) of aliased Element_Type;

   type RGA_Item is record
      Id      : Node_Id;
      Content : Element_Store;
      Len     : Natural := 0;
      Deleted : Boolean := False;
      Next    : Natural := 0;
   end record;

   type Item_Array is array (Positive range <>) of aliased RGA_Item;

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
