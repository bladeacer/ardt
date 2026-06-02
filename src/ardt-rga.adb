package body Ardt.Rga with
  SPARK_Mode
is

   function Size (R : RGA) return Natural is
   begin
      return R.Sz;
   end Size;

   function Get (R : RGA; Pos : Positive) return Element_Type is
   begin
      return R.Nodes (Pos).Value;
   end Get;

   procedure Insert (R     : in out RGA;
                     Pos   : Positive;
                     Id    : Node_Id;
                     Value : Element_Type) is
   begin
      for I in reverse Pos .. R.Sz loop
         R.Nodes (I + 1) := R.Nodes (I);
      end loop;
      R.Nodes (Pos) := (Id, Value, False);
      R.Sz := R.Sz + 1;
   end Insert;

   function Find_Node (R : RGA; Id : Node_Id) return Natural;

   procedure Delete (R   : in out RGA;
                     Pos : Positive) is
   begin
      R.Nodes (Pos).Deleted := True;
   end Delete;

   procedure Delete_Node (R : in out RGA; Id : Node_Id) is
      Idx : constant Natural := Find_Node (R, Id);
   begin
      if Idx > 0 then
         R.Nodes (Idx).Deleted := True;
      end if;
   end Delete_Node;

   function Find_Node (R : RGA; Id : Node_Id) return Natural is
   begin
      for I in 1 .. R.Sz loop
         if R.Nodes (I).Id = Id then
            return I;
         end if;
         pragma Loop_Invariant
           (for all J in 1 .. I - 1 => R.Nodes (J).Id /= Id);
      end loop;
      return 0;
   end Find_Node;

   use type Ardt.Core.Replica_Id;

   function Id_Less (Left, Right : Node_Id) return Boolean is
     (Left.Seq < Right.Seq or else
        (Left.Seq = Right.Seq and then Left.Replica < Right.Replica));

   procedure Merge (Target : in out RGA;
                    Source : RGA) is
      Target_Idx : Natural;
      Src_Idx    : Natural;
      Tmp        : RGA_Node;
   begin
      Target_Idx := 1;
      Src_Idx := 1;
      while Src_Idx <= Source.Sz
        and then Target_Idx <= Target.Sz
      loop
         if Find_Node (Target, Source.Nodes (Src_Idx).Id) > 0 then
            Src_Idx := Src_Idx + 1;
         elsif Id_Less (Target.Nodes (Target_Idx).Id,
                        Source.Nodes (Src_Idx).Id) then
            Target_Idx := Target_Idx + 1;
         else
            if Target.Sz < Target.Capacity then
               for J in reverse Target_Idx .. Target.Sz loop
                  Tmp := Target.Nodes (J);
                  Target.Nodes (J + 1) := Tmp;
               end loop;
               Target.Nodes (Target_Idx) := Source.Nodes (Src_Idx);
               Target.Sz := Target.Sz + 1;
            end if;
            Target_Idx := Target_Idx + 1;
            Src_Idx := Src_Idx + 1;
         end if;
         pragma Loop_Invariant (Src_Idx <= Source.Sz + 1);
         pragma Loop_Invariant (Target_Idx <= Target.Sz + 1);
      end loop;
      while Src_Idx <= Source.Sz
        and then Target.Sz < Target.Capacity
      loop
         if Find_Node (Target, Source.Nodes (Src_Idx).Id) = 0 then
            Target.Sz := Target.Sz + 1;
            Target.Nodes (Target.Sz) := Source.Nodes (Src_Idx);
         end if;
         Src_Idx := Src_Idx + 1;
         pragma Loop_Invariant (Src_Idx <= Source.Sz + 1);
      end loop;
   end Merge;

   function "=" (Left, Right : RGA) return Boolean is
   begin
      if Left.Sz /= Right.Sz then
         return False;
      end if;
      for I in 1 .. Left.Sz loop
         if Left.Nodes (I).Id /= Right.Nodes (I).Id
           or else Left.Nodes (I).Value /= Right.Nodes (I).Value
           or else Left.Nodes (I).Deleted /= Right.Nodes (I).Deleted
         then
            return False;
         end if;
         pragma Loop_Invariant
           (for all J in 1 .. I - 1 =>
              Left.Nodes (J).Id = Right.Nodes (J).Id and
              Left.Nodes (J).Value = Right.Nodes (J).Value and
              Left.Nodes (J).Deleted = Right.Nodes (J).Deleted);
      end loop;
      return True;
   end "=";

end Ardt.Rga;
