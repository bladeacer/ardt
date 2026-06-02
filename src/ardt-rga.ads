with Ardt.Core;

generic
   type Element_Type is private;
   Max_RGA_Size : Positive;
package Ardt.Rga with
  SPARK_Mode
is

   type Node_Id is record
      Replica : Core.Replica_Id;
      Seq     : Natural;
   end record;

   type RGA_Node is record
      Id      : Node_Id;
      Value   : Element_Type;
      Deleted : Boolean := False;
   end record;

   type Node_Array is array (Positive range <>) of RGA_Node;

   type RGA (Capacity : Positive) is private;

   function Size (R : RGA) return Natural;

   function Length (R : RGA) return Natural is (Size (R));

   function Get (R : RGA; Pos : Positive) return Element_Type;

   procedure Insert (R     : in out RGA;
                     Pos   : Positive;
                     Id    : Node_Id;
                     Value : Element_Type);

   procedure Delete (R   : in out RGA;
                     Pos : Positive);

   procedure Delete_Node (R : in out RGA; Id : Node_Id);

   procedure Merge (Target : in out RGA;
                    Source : RGA);

   function "=" (Left, Right : RGA) return Boolean;

private

   type RGA (Capacity : Positive) is record
      Nodes : Node_Array (1 .. Capacity);
      Sz    : Natural := 0;
   end record;

end Ardt.Rga;
