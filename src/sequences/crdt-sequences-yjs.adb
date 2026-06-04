with CRDT.Core.LEB128;
with CRDT.Serialization;

package body CRDT.Sequences.Yjs with
   SPARK_Mode => Off
is

   use type CRDT.Core.Replica_Id;

   --------------------
   --  Id utilities  --
   --------------------

   function Id_Less (Left, Right : Node_Id) return Boolean is
     (Left.Seq < Right.Seq or else
         (Left.Seq = Right.Seq and then Left.Replica < Right.Replica));

   function Id_Eq (Left, Right : Node_Id) return Boolean is
     (Left.Replica = Right.Replica and then Left.Seq = Right.Seq);

   --------------------
   --  Item helpers  --
   --------------------

   function Alloc_Item (R : in out RGA) return Natural is
      Idx : Natural;
   begin
      if R.Free /= 0 then
         Idx := R.Free;
         R.Free := R.Items (R.Free).Next;
         R.Items (Idx).Next := 0;
         return Idx;
      elsif R.Count < R.Item_Capacity then
         R.Count := R.Count + 1;
         return R.Count;
      end if;
      return 0;
   end Alloc_Item;

   procedure Free_Item (R : in out RGA; Idx : Natural) is
   begin
      R.Items (Idx).Len := 0;
      R.Items (Idx).Deleted := False;
      R.Items (Idx).Next := R.Free;
      R.Items (Idx).Id := (Replica => 1, Seq => 0);
      R.Free := Idx;
   end Free_Item;

   function New_Item (R    : in out RGA;
                       Id   : Node_Id;
                       Val  : Element_Type;
                       Size : Natural := 1) return Natural
   is
      Idx : constant Natural := Alloc_Item (R);
   begin
      if Idx > 0 then
         R.Items (Idx).Id := Id;
         R.Items (Idx).Len := Size;
         if Size = 1 then
            R.Items (Idx).Content (1) := Val;
         end if;
         R.Total := R.Total + Size;
      end if;
      return Idx;
   end New_Item;

   function Copy_Item (R : in out RGA; Src : RGA_Item) return Natural is
      Idx : constant Natural := Alloc_Item (R);
   begin
      if Idx > 0 then
         R.Items (Idx) := Src;
         R.Items (Idx).Next := 0;
         R.Total := R.Total + Src.Len;
      end if;
      return Idx;
   end Copy_Item;

   procedure Remove_Item (R : in out RGA; Idx : Natural) is
   begin
      R.Total := R.Total - R.Items (Idx).Len;
      Free_Item (R, Idx);
   end Remove_Item;

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
         if R.Items (Cur).Id.Replica = Id.Replica
           and then R.Items (Cur).Id.Seq = Id.Seq
         then
            return Cur;
         end if;
         Cur := R.Items (Cur).Next;
      end loop;
      return 0;
   end Find_Node;

   procedure Link_After (R : in out RGA; After, New_Idx : Natural) is
   begin
      R.Items (New_Idx).Next := R.Items (After).Next;
      R.Items (After).Next := New_Idx;
   end Link_After;

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

   procedure Find_Physical_Pos
     (R        : RGA;
       Pos      : Positive;
       Item_Idx : out Natural;
       Offset   : out Positive)
   is
      P : Natural := Pos;
      Cur : Natural := R.Head;
   begin
      while Cur /= 0 loop
         if P <= R.Items (Cur).Len then
            Item_Idx := Cur;
            Offset := P;
            return;
         end if;
         P := P - R.Items (Cur).Len;
         Cur := R.Items (Cur).Next;
      end loop;
      Item_Idx := 0;
      Offset := (if P = 0 then 1 else P);
   end Find_Physical_Pos;

   procedure Split_At (R          : in out RGA;
                        Idx        : Natural;
                        Offset     : Positive;
                        Right_Idx  : out Natural)
   is
      Orig   : RGA_Item renames R.Items (Idx);
      Rlen   : constant Natural := Orig.Len - Offset + 1;
   begin
      Right_Idx := 0;
      if Offset > Orig.Len then
         return;
      end if;

      Right_Idx := Alloc_Item (R);
      if Right_Idx = 0 then
         return;
      end if;

      declare
         Right : RGA_Item renames R.Items (Right_Idx);
      begin
         Right.Id := (Orig.Id.Replica,
                       Orig.Id.Seq + Offset - 1);
         Right.Len := Rlen;
         for I in 1 .. Rlen loop
            Right.Content (I) := Orig.Content (Offset + I - 1);
         end loop;
         Right.Deleted := Orig.Deleted;
         Right.Next := Orig.Next;
      end;

      Orig.Len := Offset - 1;
      Orig.Next := Right_Idx;
   end Split_At;

   --------------------
   --  Iterator impl --
   --------------------

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
      Item_Idx : Natural;
      Offset   : Positive;
   begin
      Find_Physical_Pos (Container, Position.Pos, Item_Idx, Offset);
      if Item_Idx = 0 then
         raise Constraint_Error with "RGA element: position out of range";
      end if;
      return Container.Items (Item_Idx).Content (Offset);
   end Element;

   --------------------
   --  Public ops    --
   --------------------

   function Count (R : RGA) return Natural is
   begin
      return R.Count;
   end Count;

   function Size (R : RGA) return Natural is
   begin
      return R.Total;
   end Size;

   function Get (R : RGA; Pos : Positive) return Element_Type is
      Item_Idx : Natural;
      Offset   : Positive;
   begin
      Find_Physical_Pos (R, Pos, Item_Idx, Offset);
      if Item_Idx = 0 then
         raise Constraint_Error with "RGA.Get: position out of range";
      end if;
      return R.Items (Item_Idx).Content (Offset);
   end Get;

   procedure Insert (R     : in out RGA;
                      Pos   : Positive;
                      Id    : Node_Id;
                      Value : Element_Type) is
   begin
      Insert_Bulk (R, Pos, Id, (1 => Value));
   end Insert;

   procedure Insert_Bulk (R      : in out RGA;
                           Pos    : Positive;
                           Id     : Node_Id;
                           Values : Element_Array) is
       VLen     : constant Natural := Values'Length;
       Item_Idx : Natural;
       Offset   : Positive;
       New_Idx  : Natural;
    begin
       if VLen = 0 then
          return;
       end if;

       if VLen > Max_Stride then
          raise Constraint_Error with
            "Insert_Bulk: values length exceeds Max_Stride";
       end if;

       if R.Head = 0 then
          New_Idx := New_Item (R, Id, Values (Values'First), VLen);
          if New_Idx > 0 then
             for I in 1 .. VLen loop
                R.Items (New_Idx).Content (I) := Values (Values'First + I - 1);
             end loop;
             R.Head := New_Idx;
          end if;
          return;
       end if;

       Find_Physical_Pos (R, Pos, Item_Idx, Offset);

       if Item_Idx = 0 then
          New_Idx := New_Item (R, Id, Values (Values'First), VLen);
          if New_Idx > 0 then
             for I in 1 .. VLen loop
                R.Items (New_Idx).Content (I) := Values (Values'First + I - 1);
             end loop;
             Append_Item (R, New_Idx);
          end if;
          return;
       end if;

       if Offset = 1 then
          New_Idx := New_Item (R, Id, Values (Values'First), VLen);
          if New_Idx > 0 then
             for I in 1 .. VLen loop
                R.Items (New_Idx).Content (I) := Values (Values'First + I - 1);
             end loop;
             Link_Before (R, Item_Idx, New_Idx);
          end if;
          return;
       end if;

       declare
          Right_Idx : Natural;
       begin
          Split_At (R, Item_Idx, Offset, Right_Idx);
          New_Idx := New_Item (R, Id, Values (Values'First), VLen);
          if New_Idx > 0 then
             for I in 1 .. VLen loop
                R.Items (New_Idx).Content (I) := Values (Values'First + I - 1);
             end loop;
             R.Items (Item_Idx).Next := New_Idx;
             R.Items (New_Idx).Next := Right_Idx;
          end if;
       end;
    end Insert_Bulk;

    procedure Delete (R : in out RGA; Pos : Positive) is
       Item_Idx : Natural;
       Offset   : Positive;
    begin
       Find_Physical_Pos (R, Pos, Item_Idx, Offset);
       if Item_Idx > 0 then
          R.Items (Item_Idx).Deleted := True;
       end if;
    end Delete;

    procedure Delete_Node (R : in out RGA; Id : Node_Id) is
       Idx : constant Natural := Find_Node (R, Id);
    begin
       if Idx > 0 then
          R.Items (Idx).Deleted := True;
       end if;
    end Delete_Node;

    --------------------
    --  Merge         --
    --------------------

     procedure Merge (Target : in out RGA; Source : RGA) is
        type Src_Ref is record
           Idx : Natural;
           Id  : Node_Id;
        end record;
        type Src_Array is array (Positive range <>) of Src_Ref;

        Srcs     : Src_Array (1 .. Max_Items);
        Src_Last : Natural := 0;
        S_Idx    : Natural := Source.Head;
     begin
        while S_Idx /= 0 loop
           if Find_Node (Target, Source.Items (S_Idx).Id) = 0 then
              Src_Last := Src_Last + 1;
              Srcs (Src_Last) := (Idx => S_Idx, Id => Source.Items (S_Idx).Id);
           end if;
           S_Idx := Source.Items (S_Idx).Next;
        end loop;

        for I in 1 .. Src_Last loop
           for J in reverse I + 1 .. Src_Last loop
              if Id_Less (Srcs (J).Id, Srcs (J - 1).Id) then
                 declare
                    Tmp : constant Src_Ref := Srcs (J);
                 begin
                    Srcs (J) := Srcs (J - 1);
                    Srcs (J - 1) := Tmp;
                 end;
              end if;
           end loop;
        end loop;

        for I in 1 .. Src_Last loop
           declare
              New_Idx : constant Natural :=
                Copy_Item (Target, Source.Items (Srcs (I).Idx));
              T_Idx   : Natural := Target.Head;
              Ins     : Boolean := False;
           begin
              if New_Idx > 0 then
                 while T_Idx /= 0 and not Ins loop
                    if Id_Less (Srcs (I).Id, Target.Items (T_Idx).Id) then
                       Link_Before (Target, T_Idx, New_Idx);
                       Ins := True;
                    end if;
                    T_Idx := Target.Items (T_Idx).Next;
                 end loop;
                 if not Ins then
                    Append_Item (Target, New_Idx);
                 end if;
              end if;
           end;
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
            or else Left.Items (L_Idx).Len /= Right.Items (R_Idx).Len
            or else Left.Items (L_Idx).Deleted /= Right.Items (R_Idx).Deleted
          then
             return False;
          end if;
          for I in 1 .. Left.Items (L_Idx).Len loop
             if Left.Items (L_Idx).Content (I) /=
                Right.Items (R_Idx).Content (I)
             then
                return False;
             end if;
          end loop;
          L_Idx := Left.Items (L_Idx).Next;
          R_Idx := Right.Items (R_Idx).Next;
       end loop;
    end "=";

    --------------------------
    --  State Vector        --
    --------------------------

    procedure Compute_State_Vector
      (R     : RGA;
       SV    : out Replica_Max_Seq_Array;
       Count : out Natural)
    is
       Cur : Natural := R.Head;
       Idx : Natural := 1;
       Max_SV : Natural;
    begin
       Count := 0;
       while Cur /= 0 and Idx <= SV'Length loop
          Max_SV := R.Items (Cur).Id.Seq + R.Items (Cur).Len - 1;
          SV (Idx) := (Replica => R.Items (Cur).Id.Replica,
                        Max_Seq => Max_SV);
          Count := Count + 1;
          Cur := R.Items (Cur).Next;
          Idx := Idx + 1;
       end loop;
    end Compute_State_Vector;

    function Is_Newer (Item     : RGA_Item;
                        Remote_SV : Replica_Max_Seq_Array;
                        SV_Count  : Natural) return Boolean
    is
    begin
       for I in 1 .. SV_Count loop
          if Remote_SV (I).Replica = Item.Id.Replica then
             return Item.Id.Seq > Remote_SV (I).Max_Seq;
          end if;
       end loop;
       return True;
    end Is_Newer;

    procedure Sync_Delta
      (Target    : in out RGA;
       Source    : RGA;
       Remote_SV : Replica_Max_Seq_Array;
       SV_Count  : Natural)
    is
       S_Idx : Natural := Source.Head;
    begin
       while S_Idx /= 0 loop
          if Is_Newer (Source.Items (S_Idx), Remote_SV, SV_Count)
            and then Find_Node (Target, Source.Items (S_Idx).Id) = 0
          then
             declare
                T_Idx   : Natural := Target.Head;
                Ins     : Boolean := False;
                New_Idx : constant Natural :=
                  Copy_Item (Target, Source.Items (S_Idx));
             begin
                if New_Idx > 0 then
                   while T_Idx /= 0 and not Ins loop
                      if Id_Less (Source.Items (S_Idx).Id,
                                 Target.Items (T_Idx).Id)
                      then
                         Link_Before (Target, T_Idx, New_Idx);
                         Ins := True;
                      end if;
                      T_Idx := Target.Items (T_Idx).Next;
                   end loop;
                   if not Ins then
                      Append_Item (Target, New_Idx);
                   end if;
                end if;
             end;
          end if;
          S_Idx := Source.Items (S_Idx).Next;
       end loop;
    end Sync_Delta;

    --------------------------
    --  Tombstone GC        --
    --------------------------

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
             Remove_Item (R, Cur);
          else
             Prev := Cur;
          end if;
          Cur := Next;
       end loop;
    end Compact;

    --------------------------
    --  Serialization       --
    --------------------------

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
             Core.LEB128.Encode (Stream, Item.Items (Cur).Len);
             Boolean'Write (Stream, Item.Items (Cur).Deleted);
             for I in 1 .. Item.Items (Cur).Len loop
                Element_Type'Write (Stream, Item.Items (Cur).Content (I));
             end loop;
             Cur := Item.Items (Cur).Next;
          end loop;
       end;
    end Write_RGA;

    procedure Read_RGA
      (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
       Item   : out RGA)
    is
       use Ada.Streams;
       use CRDT.Serialization;
       Kind      : Protocol_Kind;
       Total     : Natural;
       Num_Items : Natural;
       Id        : Node_Id;
       Len       : Natural;
       Deleted   : Boolean;
       Prev_Idx  : Natural := 0;
       New_Idx   : Natural;
    begin
       Read_Header (Stream, Kind, Total, Num_Items);

        if Num_Items > Item.Item_Capacity then
           raise Constraint_Error with
             "RGA Read_RGA: item count" & Natural'Image (Num_Items) &
             " exceeds capacity" & Natural'Image (Item.Item_Capacity);
        end if;

        Item.Total := Total;
        Item.Head := 0;
        Item.Count := 0;
        Item.Free := 0;

        for J in 1 .. Num_Items loop
           Node_Id'Read (Stream, Id);
           Read_Natural (Kind, Stream, Len);

           if Len > Max_Stride then
              raise Constraint_Error with
                "RGA Read_RGA: item len" & Natural'Image (Len) &
                " exceeds Max_Stride" & Natural'Image (Max_Stride);
           end if;

           Boolean'Read (Stream, Deleted);

           New_Idx := Alloc_Item (Item);
           if New_Idx > 0 then
              Item.Count := J;
           end if;

           if New_Idx > 0 then
              Item.Items (New_Idx).Id := Id;
              Item.Items (New_Idx).Len := Len;
              Item.Items (New_Idx).Deleted := Deleted;
              for I in 1 .. Len loop
                 Element_Type'Read (Stream, Item.Items (New_Idx).Content (I));
              end loop;
             if Prev_Idx = 0 then
                Item.Head := New_Idx;
             else
                Item.Items (Prev_Idx).Next := New_Idx;
             end if;
             Prev_Idx := New_Idx;
          end if;
       end loop;
    end Read_RGA;

end CRDT.Sequences.Yjs;
