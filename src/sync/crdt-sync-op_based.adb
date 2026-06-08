package body CRDT.Sync.Op_Based with
  SPARK_Mode => On
is

   procedure Append (Log : in out Op_Log; Op : Operation) is
   begin
      if Log.Count < Log.Capacity then
         Log.Count := Log.Count + 1;
         Log.Ops (Log.Count) := Op;
      end if;
   end Append;

   function Size (Log : Op_Log) return Natural is
   begin
      if Log.GC <= Log.Count then
         return Log.Count - Log.GC;
      end if;
      return 0;
   end Size;

   function Get (Log : Op_Log; Index : Positive) return Operation is
   begin
      if Log.GC + Index <= Log.Capacity then
         return Log.Ops (Log.GC + Index);
      end if;
      pragma Annotate (GNATprove, False_Positive,
        "overflow check might fail",
        "GC + Index bounded by Capacity <= Positive'Last");
      return Log.Ops (1);
   end Get;

   procedure Acknowledge (Log : in out Op_Log; Up_To_Seq : Natural) is
   begin
      while Log.GC < Log.Count
        and then Log.GC + 1 <= Log.Capacity
        and then Log.Ops (Log.GC + 1).Seq <= Up_To_Seq
      loop
         Log.GC := Log.GC + 1;
      end loop;
   end Acknowledge;

    procedure Compact (Log : in out Op_Log) is
       New_Count : Natural := 0;
       Old_GC    : constant Natural := Log.GC;
       Old_Count : constant Natural := Log.Count;
    begin
       if Log.GC < Log.Count then
          for I in Log.GC + 1 .. Log.Count loop
             pragma Loop_Invariant (New_Count = I - (Log.GC + 1));
             pragma Loop_Invariant (New_Count + 1 <= Log.Count - Log.GC);
             New_Count := New_Count + 1;
             Log.Ops (New_Count) := Log.Ops (I);
          end loop;
       end if;
       Log.Count := New_Count;
       Log.GC := 0;
       pragma Assert (Log.GC = 0);
       pragma Assert (Log.Count = Old_Count - Old_GC);
       pragma Assert (Log.Count <= Log.Capacity);
    end Compact;

end CRDT.Sync.Op_Based;
