package body CRDT.Sync.Op_Based is

   procedure Append (Log : in out Op_Log; Op : Operation) is
   begin
      Log.Count := Log.Count + 1;
      Log.Ops (Log.Count) := Op;
   end Append;

   function Size (Log : Op_Log) return Natural is
   begin
      return Log.Count - Log.GC;
   end Size;

   function Get (Log : Op_Log; Index : Positive) return Operation is
   begin
      return Log.Ops (Log.GC + Index);
   end Get;

   procedure Acknowledge (Log : in out Op_Log; Up_To_Seq : Natural) is
   begin
      while Log.GC < Log.Count
        and then Log.Ops (Log.GC + 1).Seq <= Up_To_Seq
      loop
         Log.GC := Log.GC + 1;
      end loop;
   end Acknowledge;

   procedure Compact (Log : in out Op_Log) is
      New_Count : Natural := 0;
   begin
      for I in Log.GC + 1 .. Log.Count loop
         New_Count := New_Count + 1;
         Log.Ops (New_Count) := Log.Ops (I);
      end loop;
      Log.Count := New_Count;
      Log.GC := 0;
   end Compact;

end CRDT.Sync.Op_Based;
