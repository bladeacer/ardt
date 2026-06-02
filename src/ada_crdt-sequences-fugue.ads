--  Fugue-style tree-based RGA engine.
--  Replaces flat linked lists with a binary search tree hierarchy
--  designed to eliminate string interleaving (the "zipper" bug
--  when users type concurrently at the same position).
--
--  Node_Id includes a Depth component for tree positioning.
--  In-order traversal produces the document sequence.
with Ada.Streams;
with Ada_CRDT.Core;

generic
   type Element_Type is private;
   Max_Items   : Positive;
package Ada_CRDT.Sequences.Fugue with
  SPARK_Mode
is

   type Node_Id is record
      Replica : Core.Replica_Id;
      Seq     : Natural;
      Depth   : Natural := 0;
   end record;

   type Element_Array is array (Positive range <>) of Element_Type;

   type RGA (Capacity : Positive) is private;

   --  Standard Ada iterator support
   type Cursor is private;

   function Has_Element (Position : Cursor) return Boolean;
   function Has_Element (Container : RGA; Position : Cursor) return Boolean;
   function First (Container : RGA) return Cursor;
   procedure Next (Container : RGA; Position : in out Cursor);
   function Element (Container : RGA; Position : Cursor) return Element_Type;

   function Count (R : RGA) return Natural;
   function Size (R : RGA) return Natural;
   function Length (R : RGA) return Natural is (Size (R));
   function Get (R : RGA; Pos : Positive) return Element_Type;

   procedure Insert (R     : in out RGA;
                     Pos   : Positive;
                     Id    : Node_Id;
                     Value : Element_Type);

   procedure Insert_Bulk (R      : in out RGA;
                          Pos    : Positive;
                          Id     : Node_Id;
                          Values : Element_Array);

   procedure Delete (R   : in out RGA;
                     Pos : Positive);

   procedure Delete_Node (R : in out RGA; Id : Node_Id);

   procedure Merge (Target : in out RGA;
                    Source : RGA);

   function "=" (Left, Right : RGA) return Boolean;

   procedure Compact (R : in out RGA);

   procedure Write_RGA
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Item   : RGA);

   procedure Read_RGA
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Item   : out RGA);

private

   type RGA_Item is record
      Id      : Node_Id;
      Value   : Element_Type;
      Deleted : Boolean := False;
      Parent  : Natural := 0;
      Left    : Natural := 0;
      Right   : Natural := 0;
   end record;

   type Item_Array is array (Positive range <>) of RGA_Item;

   type Cursor is record
      Total : Natural := 0;
      Pos   : Natural := 0;
   end record;

   type RGA (Capacity : Positive) is record
      Items   : Item_Array (1 .. Capacity);
      Root    : Natural := 0;
      Count   : Natural := 0;
      Free    : Natural := 0;
      Total   : Natural := 0;
   end record;

   for RGA'Write use Write_RGA;
   for RGA'Read  use Read_RGA;

end Ada_CRDT.Sequences.Fugue;
