with Ada.Streams;
with CRDT.Core.LEB128;

package body CRDT.Sequences.Naive with
  SPARK_Mode => Off
is

   use type Core.Replica_Id;

   function Id_Less (Left, Right : Node_Id) return Boolean is
     (Left.Seq < Right.Seq or else
        (Left.Seq = Right.Seq and then Left.Replica < Right.Replica));

   function Id_Eq (Left, Right : Node_Id) return Boolean is
     (Left.Replica = Right.Replica and then Left.Seq = Right.Seq);

   function Alloc_Item (R : in out RGA) return Natural is
      Idx : Natural;
   begin
      if R.Free /= 0 then
         Idx := R.Free;
         R.Free := R.Items (R.Free).Next;
         R.Items (Idx).Next := 0;
         return Idx;
      elsif R.Count < R.Capacity then
         R.Count := R.Count + 1;
         return R.Count;
      end if;
      return 0;
   end Alloc_Item;

   procedure Free_Item (R : in out RGA; Idx : Natural) is
   begin
      R.Items (Idx).Deleted := False;
      R.Items (Idx).Next := R.Free;
      R.Items (Idx).Id := (Replica => 1, Seq => 0);
      R.Free := Idx;
   end Free_Item;

   function New_Item (R : in out RGA; Id : Node_Id; Val : Element_Type) return Natural is
      Idx : constant Natural := Alloc_Item (R);
   begin
      if Idx > 0 then
         R.Items (Idx).Id := Id;
         R.Items (Idx).Value := Val;
         R.Total := R.Total + 1;
      end if;
      return Idx;
   end New_Item;

   function Copy_Item (R : in out RGA; Src : RGA_Item) return Natural is
      Idx : constant Natural := Alloc_Item (R);
   begin
      if Idx > 0 then
         R.Items (Idx) := Src;
         R.Items (Idx).Next := 0;
         R.Total := R.Total + 1;
      end if;
      return Idx;
   end Copy_Item;

   function Find_Last (R : RGA) return Natural is
      Cur : Natural := R.Head;
   begin
      if Cur = 0 then
         return 0;
      end if;
      while R.Items (Cur).Next /= 0 loop
         Cur := R.Items (Cur).Next;
      end loop;
      return Cur;
   end Find_Last;

   function Find_Node (R : RGA; Id : Node_Id) return Natural is
      Cur : Natural := R.Head;
   begin
      while Cur /= 0 loop
         if R.Items (Cur).Id = Id then
            return Cur;
         end if;
         Cur := R.Items (Cur).Next;
      end loop;
      return 0;
   end Find_Node;

   procedure Link_Before (R : in out RGA; Before, New_Idx : Natural) is
      Cur : Natural;
   begin
      if Before = R.Head then
         R.Items (New_Idx).Next := R.Head;
         R.Head := New_Idx;
      else
         Cur := R.Head;
         while Cur /= 0 and then R.Items (Cur).Next /= Before loop
            Cur := R.Items (Cur).Next;
         end loop;
         if Cur /= 0 then
            R.Items (Cur).Next := New_Idx;
            R.Items (New_Idx).Next := Before;
         end if;
      end if;
   end Link_Before;

   procedure Append_Item (R : in out RGA; Idx : Natural) is
      Last : constant Natural := Find_Last (R);
   begin
      if Last = 0 then
         R.Head := Idx;
      else
         R.Items (Last).Next := Idx;
      end if;
   end Append_Item;

   function Find_Pos (R : RGA; Pos : Positive) return Natural is
      P : Natural := Pos;
      Cur : Natural := R.Head;
   begin
      while Cur /= 0 loop
         if P = 1 then
            return Cur;
         end if;
         P := P - 1;
         Cur := R.Items (Cur).Next;
      end loop;
      return 0;
   end Find_Pos;

   -- Iterator
   function Has_Element (Position : Cursor) return Boolean is
   begin
      return Position.Pos in 1 .. Position.Total;
   end Has_Element;

   function Has_Element (Container : RGA; Position : Cursor) return Boolean is
   begin
      return Position.Pos in 1 .. Container.Total;
   end Has_Element;

   function First (Container : RGA) return Cursor is
   begin
      if Container.Total = 0 then
         return Cursor'(Total => 0, Pos => 0);
      end if;
      return Cursor'(Total => Container.Total, Pos => 1);
   end First;

   procedure Next (Container : RGA; Position : in out Cursor) is
   begin
      if Position.Pos < Container.Total then
         Position.Pos := Position.Pos + 1;
      else
         Position.Pos := 0;
      end if;
   end Next;

   function Element (Container : RGA; Position : Cursor) return Element_Type is
      Idx : constant Natural := Find_Pos (Container, Position.Pos);
   begin
      if Idx = 0 then
         raise Constraint_Error with "Naive element: position out of range";
      end if;
      return Container.Items (Idx).Value;
   end Element;

   -- Public ops
   function Count (R : RGA) return Natural is (R.Count);

   function Size (R : RGA) return Natural is (R.Total);

   function Get (R : RGA; Pos : Positive) return Element_Type is
      Idx : constant Natural := Find_Pos (R, Pos);
   begin
      if Idx = 0 then
         raise Constraint_Error with "RGA.Get: position out of range";
      end if;
      return R.Items (Idx).Value;
   end Get;

   procedure Insert (R : in out RGA; Pos : Positive; Id : Node_Id; Value : Element_Type) is
   begin
      if R.Head = 0 then
         declare
            Idx : constant Natural := New_Item (R, Id, Value);
         begin
            if Idx > 0 then
               R.Head := Idx;
            end if;
         end;
         return;
      end if;

      declare
         Before : constant Natural := Find_Pos (R, Pos);
         New_Idx : constant Natural := New_Item (R, Id, Value);
      begin
         if New_Idx > 0 then
            if Before = 0 then
               Append_Item (R, New_Idx);
            else
               Link_Before (R, Before, New_Idx);
            end if;
         end if;
      end;
   end Insert;

   procedure Insert_Bulk (R : in out RGA; Pos : Positive; Id : Node_Id; Values : Element_Array) is
   begin
      for I in Values'Range loop
         Insert (R, Pos + (I - Values'First),
                 (Replica => Id.Replica, Seq => Id.Seq + (I - Values'First)),
                 Values (I));
      end loop;
   end Insert_Bulk;

   procedure Delete (R : in out RGA; Pos : Positive) is
      Idx : constant Natural := Find_Pos (R, Pos);
   begin
      if Idx > 0 then
         R.Items (Idx).Deleted := True;
      end if;
   end Delete;

   procedure Delete_Node (R : in out RGA; Id : Node_Id) is
      Idx : constant Natural := Find_Node (R, Id);
   begin
      if Idx > 0 then
         R.Items (Idx).Deleted := True;
      end if;
   end Delete_Node;

   procedure Merge (Target : in out RGA; Source : RGA) is
      T_Idx : Natural;
      S_Idx : Natural;
   begin
      T_Idx := Target.Head;
      S_Idx := Source.Head;

      while S_Idx /= 0 loop
         if Find_Node (Target, Source.Items (S_Idx).Id) /= 0 then
            S_Idx := Source.Items (S_Idx).Next;
         elsif T_Idx = 0 then
            declare
               New_Idx : Natural;
            begin
               while S_Idx /= 0 loop
                  if Find_Node (Target, Source.Items (S_Idx).Id) = 0 then
                     New_Idx := Copy_Item (Target, Source.Items (S_Idx));
                     if New_Idx > 0 then
                        Append_Item (Target, New_Idx);
                     end if;
                  end if;
                  S_Idx := Source.Items (S_Idx).Next;
               end loop;
            end;
            exit;
         elsif Id_Less (Target.Items (T_Idx).Id, Source.Items (S_Idx).Id) then
            T_Idx := Target.Items (T_Idx).Next;
         else
            declare
               New_Idx : constant Natural := Copy_Item (Target, Source.Items (S_Idx));
            begin
               if New_Idx > 0 then
                  Link_Before (Target, T_Idx, New_Idx);
               end if;
            end;
            S_Idx := Source.Items (S_Idx).Next;
         end if;
      end loop;
   end Merge;

   function "=" (Left, Right : RGA) return Boolean is
      L_Idx : Natural := Left.Head;
      R_Idx : Natural := Right.Head;
   begin
      loop
         if L_Idx = 0 and R_Idx = 0 then
            return True;
         end if;
         if L_Idx = 0 or R_Idx = 0 then
            return False;
         end if;
         if Left.Items (L_Idx).Id /= Right.Items (R_Idx).Id
           or else Left.Items (L_Idx).Value /= Right.Items (R_Idx).Value
           or else Left.Items (L_Idx).Deleted /= Right.Items (R_Idx).Deleted
         then
            return False;
         end if;
         L_Idx := Left.Items (L_Idx).Next;
         R_Idx := Right.Items (R_Idx).Next;
      end loop;
   end "=";

   procedure Compact (R : in out RGA) is
      Cur  : Natural := R.Head;
      Prev : Natural := 0;
      Next : Natural;
   begin
      while Cur /= 0 loop
         Next := R.Items (Cur).Next;
         if R.Items (Cur).Deleted then
            if Prev = 0 then
               R.Head := Next;
            else
               R.Items (Prev).Next := Next;
            end if;
            Free_Item (R, Cur);
            R.Total := R.Total - 1;
         else
            Prev := Cur;
         end if;
         Cur := Next;
      end loop;
   end Compact;

   -- Serialization
   procedure Write_RGA
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Item   : RGA)
   is
      use Ada.Streams;
   begin
      Core.LEB128.Encode (Stream, Core.Protocol_Version);
      Core.LEB128.Encode (Stream, Item.Total);
      Core.LEB128.Encode (Stream, Item.Count);
      declare
         Cur : Natural := Item.Head;
      begin
         while Cur /= 0 loop
            Node_Id'Write (Stream, Item.Items (Cur).Id);
            Boolean'Write (Stream, Item.Items (Cur).Deleted);
            Element_Type'Write (Stream, Item.Items (Cur).Value);
            Cur := Item.Items (Cur).Next;
         end loop;
      end;
   end Write_RGA;

   procedure Read_RGA
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Item   : out RGA)
   is
      use Ada.Streams;
      Ver       : Natural;
      Total     : Natural;
      Num_Items : Natural;
      Id        : Node_Id;
      Deleted   : Boolean;
      Val       : Element_Type;
      Prev_Idx  : Natural := 0;
      New_Idx   : Natural;
   begin
      Core.LEB128.Decode (Stream, Ver);
      if Ver /= Core.Protocol_Version then
         raise Constraint_Error with "unsupported protocol version";
      end if;
      Core.LEB128.Decode (Stream, Total);
      Core.LEB128.Decode (Stream, Num_Items);
      Item.Total := Total;
      Item.Head := 0;
      Item.Count := 0;
      Item.Free := 0;

      for J in 1 .. Num_Items loop
         Node_Id'Read (Stream, Id);
         Boolean'Read (Stream, Deleted);
         Element_Type'Read (Stream, Val);
         New_Idx := Alloc_Item (Item);
         if New_Idx > 0 then
            Item.Count := J;
            Item.Items (New_Idx).Id := Id;
            Item.Items (New_Idx).Deleted := Deleted;
            Item.Items (New_Idx).Value := Val;
            if Prev_Idx = 0 then
               Item.Head := New_Idx;
            else
               Item.Items (Prev_Idx).Next := New_Idx;
            end if;
            Prev_Idx := New_Idx;
         end if;
      end loop;
   end Read_RGA;

end CRDT.Sequences.Naive;
