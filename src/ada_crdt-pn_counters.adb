package body Ada_CRDT.Pn_Counters with
  SPARK_Mode => Off
is

   use type Ada_CRDT.Core.Replica_Id;

   function Find_Actor (Entries : Actor_Array;
                        Count   : Natural;
                        Actor   : Core.Replica_Id) return Natural
   is
   begin
      for I in 1 .. Count loop
         if Entries (I).Actor = Actor then
            return I;
         end if;
      end loop;
      return 0;
   end Find_Actor;

   function Value (C : PN_Counter) return Integer is
      Total : Long_Long_Integer := 0;
   begin
      for I in 1 .. C.Count loop
         Total := Total
           + Long_Long_Integer (C.Entries (I).P)
           - Long_Long_Integer (C.Entries (I).N);
      end loop;
      return Integer (Total);
   end Value;

   procedure Increment (C     : in out PN_Counter;
                        By    : Counter_Range := 1;
                        Actor : Core.Replica_Id) is
      Idx : Natural;
   begin
      Idx := Find_Actor (C.Entries, C.Count, Actor);
      if Idx = 0 then
         C.Count := C.Count + 1;
         C.Entries (C.Count) := (Actor => Actor,
                                 P     => By,
                                 N     => 0);
      else
         C.Entries (Idx).P := C.Entries (Idx).P + By;
      end if;
   end Increment;

   procedure Decrement (C     : in out PN_Counter;
                        By    : Counter_Range := 1;
                        Actor : Core.Replica_Id) is
      Idx : Natural;
   begin
      Idx := Find_Actor (C.Entries, C.Count, Actor);
      if Idx = 0 then
         C.Count := C.Count + 1;
         C.Entries (C.Count) := (Actor => Actor,
                                 P     => 0,
                                 N     => By);
      else
         C.Entries (Idx).N := C.Entries (Idx).N + By;
      end if;
   end Decrement;

   procedure Merge (Target : in out PN_Counter;
                    Source : PN_Counter) is
      T_Idx : Natural;
   begin
      for I in 1 .. Source.Count loop
         T_Idx := Find_Actor (Target.Entries, Target.Count,
                              Source.Entries (I).Actor);
         if T_Idx = 0 then
            Target.Count := Target.Count + 1;
            Target.Entries (Target.Count) := Source.Entries (I);
         else
            if Source.Entries (I).P > Target.Entries (T_Idx).P then
               Target.Entries (T_Idx).P := Source.Entries (I).P;
            end if;
            if Source.Entries (I).N > Target.Entries (T_Idx).N then
               Target.Entries (T_Idx).N := Source.Entries (I).N;
            end if;
         end if;
      end loop;
   end Merge;

end Ada_CRDT.Pn_Counters;
