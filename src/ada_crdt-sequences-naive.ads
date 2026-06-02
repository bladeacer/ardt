with Ada.Streams;
with Ada_CRDT.Core;

generic
   type Element_Type is private;
   Max_Items   : Positive;
package Ada_CRDT.Sequences.Naive with
  SPARK_Mode
is

   type Node_Id is record
      Replica : Core.Replica_Id;
      Seq     : Natural;
   end record;

   type RGA (Capacity : Positive) is private;

   type Element_Array is array (Positive range <>) of Element_Type;

   -- Iterator support
   type Cursor is private;
   function Has_Element (Position : Cursor) return Boolean;
   type Constant_Reference_Type (Element : not null access constant Element_Type) is private;

   function Iterate (Container : aliased RGA) return Cursor;
   function Constant_Ref (Container : aliased in RGA; Position : Cursor)
      return Constant_Reference_Type;

   procedure Next (Position : in out Cursor);

   -- Core operations
   function Count (R : RGA) return Natural;
   function Size (R : RGA) return Natural;
   function Length (R : RGA) return Natural is (Size (R));
   function Get (R : RGA; Pos : Positive) return Element_Type;

   procedure Insert (R : in out RGA; Pos : Positive; Id : Node_Id; Value : Element_Type);
   procedure Insert_Bulk (R : in out RGA; Pos : Positive; Id : Node_Id; Values : Element_Array);
   procedure Delete (R : in out RGA; Pos : Positive);
   procedure Delete_Node (R : in out RGA; Id : Node_Id);
   procedure Merge (Target : in out RGA; Source : RGA);
   function "=" (Left, Right : RGA) return Boolean;

   procedure Compact (R : in out RGA);

   procedure Write_RGA (Stream : not null access Ada.Streams.Root_Stream_Type'Class; Item : RGA);
   procedure Read_RGA (Stream : not null access Ada.Streams.Root_Stream_Type'Class; Item : out RGA);

private

   -- Naive: each element is its own node
   type RGA_Item is record
      Id      : Node_Id;
      Value   : aliased Element_Type;
      Deleted : Boolean := False;
      Next    : Natural := 0;
   end record;

   type Item_Array is array (Positive range <>) of RGA_Item;

   type Cursor is record
      Container : access constant RGA;
      Pos       : Natural := 0;
   end record;

   type Constant_Reference_Type (Element : not null access constant Element_Type) is
      null record;

   type RGA (Capacity : Positive) is record
      Items   : aliased Item_Array (1 .. Capacity);
      Head    : Natural := 0;
      Count   : Natural := 0;
      Free    : Natural := 0;
      Total   : Natural := 0;
   end record;

   for RGA'Write use Write_RGA;
   for RGA'Read  use Read_RGA;

end Ada_CRDT.Sequences.Naive;
