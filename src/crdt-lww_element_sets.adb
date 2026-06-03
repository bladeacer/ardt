package body CRDT.Lww_Element_Sets with
  SPARK_Mode
is

   procedure Clear (S : in out LWW_Element_Set) is
   begin
      S.Add_Size := 0;
      S.Remove_Size := 0;
   end Clear;

   use type Core.Lamport_Time;

   function Find_Index (A    : Timestamp_Array;
                        Size : Natural;
                        E    : Element_Type) return Natural
   is
   begin
      for I in 1 .. Size loop
         if A (I).Element = E then
            return I;
         end if;
         pragma Loop_Invariant (for all J in 1 .. I - 1 => A (J).Element /= E);
      end loop;
      return 0;
   end Find_Index;

   function Contains (S : LWW_Element_Set; E : Element_Type) return Boolean is
      Add_I    : constant Natural := Find_Index (S.Add_Array, S.Add_Size, E);
      Remove_I : constant Natural := Find_Index (S.Remove_Array, S.Remove_Size, E);
   begin
      if Add_I = 0 then
         return False;
      end if;
      if Remove_I = 0 then
         return True;
      end if;
      return S.Add_Array (Add_I).Time > S.Remove_Array (Remove_I).Time;
   end Contains;

   procedure Add (S  : in out LWW_Element_Set;
                  E  : Element_Type;
                  TS : Core.Lamport_Time) is
      Add_I    : Natural;
      Remove_I : Natural;
   begin
      Add_I := Find_Index (S.Add_Array, S.Add_Size, E);
      if Add_I > 0 then
         if TS > S.Add_Array (Add_I).Time then
            S.Add_Array (Add_I) := (E, TS);
         end if;
         Remove_I := Find_Index (S.Remove_Array, S.Remove_Size, E);
         if Remove_I > 0 and then TS > S.Remove_Array (Remove_I).Time then
            S.Remove_Array (Remove_I) :=
              (S.Remove_Array (S.Remove_Size).Element,
               S.Remove_Array (S.Remove_Size).Time);
            S.Remove_Size := S.Remove_Size - 1;
         end if;
      else
         S.Add_Size := S.Add_Size + 1;
         S.Add_Array (S.Add_Size) := (E, TS);
      end if;
   end Add;

   procedure Remove (S  : in out LWW_Element_Set;
                     E  : Element_Type;
                     TS : Core.Lamport_Time) is
      Add_I    : Natural;
      Remove_I : Natural;
   begin
      Add_I := Find_Index (S.Add_Array, S.Add_Size, E);
      if Add_I = 0 then
         return;
      end if;
      Remove_I := Find_Index (S.Remove_Array, S.Remove_Size, E);
      if Remove_I > 0 then
         if TS > S.Remove_Array (Remove_I).Time then
            S.Remove_Array (Remove_I) := (E, TS);
         end if;
      else
         S.Remove_Size := S.Remove_Size + 1;
         S.Remove_Array (S.Remove_Size) := (E, TS);
      end if;
   end Remove;

   procedure Merge (Target : in out LWW_Element_Set;
                    Source : LWW_Element_Set) is
   begin
      for I in 1 .. Source.Add_Size loop
         Add (Target,
              Source.Add_Array (I).Element,
              Source.Add_Array (I).Time);
      end loop;
      for I in 1 .. Source.Remove_Size loop
         Remove (Target,
                 Source.Remove_Array (I).Element,
                 Source.Remove_Array (I).Time);
      end loop;
   end Merge;

end CRDT.Lww_Element_Sets;
