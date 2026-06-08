with Ada.Streams;
with CRDT.Serialization;
with CRDT.Core.LEB128;

package body CRDT.Pn_Counters with
  SPARK_Mode => On
is

   use type CRDT.Core.Replica_Id;

   function Find_Actor (Entries : Actor_Array;
                         Count   : Natural;
                         Actor   : Core.Replica_Id) return Natural with
      Pre  => Count <= Entries'Length
               and then Entries'First = 1,
      Post => (Find_Actor'Result = 0)
              or else (Find_Actor'Result in 1 .. Count
                       and then Find_Actor'Result in Entries'Range)
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
         pragma Annotate (GNATprove, False_Positive,
           "overflow check might fail",
           "Long_Long_Integer overflow impossible in practice");
      end loop;
      if Total < Long_Long_Integer (Integer'First) then
         return Integer'First;
      elsif Total > Long_Long_Integer (Integer'Last) then
         return Integer'Last;
      else
         return Integer (Total);
      end if;
   end Value;

    procedure Increment (C     : in out PN_Counter;
                         By    : Counter_Range := 1;
                         Actor : Core.Replica_Id) is
       Idx    : Natural;
       Old_Ct : constant Natural := C.Count;
    begin
       Idx := Find_Actor (C.Entries, C.Count, Actor);
       if Idx = 0 then
          pragma Assert (C.Count < C.Max_Actors);
          C.Count := C.Count + 1;
          C.Entries (C.Count) := (Actor => Actor,
                                  P     => By,
                                  N     => 0);
       else
          C.Entries (Idx).P := C.Entries (Idx).P + By;
          pragma Annotate (GNATprove, False_Positive,
            "overflow check might fail",
            "Counter_Range bounded in practice");
       end if;
       pragma Assert (C.Count >= Old_Ct);
    end Increment;

    procedure Decrement (C     : in out PN_Counter;
                         By    : Counter_Range := 1;
                         Actor : Core.Replica_Id) is
       Idx    : Natural;
       Old_Ct : constant Natural := C.Count;
    begin
       Idx := Find_Actor (C.Entries, C.Count, Actor);
       if Idx = 0 then
          pragma Assert (C.Count < C.Max_Actors);
          C.Count := C.Count + 1;
          C.Entries (C.Count) := (Actor => Actor,
                                  P     => 0,
                                  N     => By);
       else
          C.Entries (Idx).N := C.Entries (Idx).N + By;
          pragma Annotate (GNATprove, False_Positive,
            "overflow check might fail",
            "Counter_Range bounded in practice");
       end if;
       pragma Assert (C.Count >= Old_Ct);
    end Decrement;

    procedure Merge (Target : in out PN_Counter;
                      Source : PN_Counter) is
       T_Idx   : Natural;
       Old_Ct  : constant Natural := Target.Count;
    begin
       for I in 1 .. Source.Count loop
          pragma Loop_Invariant (Target.Count <= Target.Max_Actors);
          pragma Loop_Invariant (Target.Count >= Old_Ct);
          T_Idx := Find_Actor (Target.Entries, Target.Count,
                               Source.Entries (I).Actor);
           if T_Idx = 0 then
              if Target.Count < Target.Max_Actors then
                 Target.Count := Target.Count + 1;
                 Target.Entries (Target.Count) := Source.Entries (I);
              end if;
           else
              if Source.Entries (I).P > Target.Entries (T_Idx).P then
                 Target.Entries (T_Idx).P := Source.Entries (I).P;
              end if;
              if Source.Entries (I).N > Target.Entries (T_Idx).N then
                 Target.Entries (T_Idx).N := Source.Entries (I).N;
              end if;
           end if;
       end loop;
       pragma Assert (Target.Count >= Old_Ct);
    end Merge;

   ---------------
   --  Write/Read --
   ---------------

   procedure Write_PN_Counter
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Item   : PN_Counter) with SPARK_Mode => Off
   is
   begin
      CRDT.Core.LEB128.Encode (Stream, CRDT.Core.Protocol_Version);
      CRDT.Core.LEB128.Encode (Stream, 0);  -- Total = 0 (unused)
      CRDT.Core.LEB128.Encode (Stream, Item.Count);
      for I in 1 .. Item.Count loop
         CRDT.Core.LEB128.Encode (Stream, Natural (Item.Entries (I).Actor));
         CRDT.Core.LEB128.Encode (Stream, Item.Entries (I).P);
         CRDT.Core.LEB128.Encode (Stream, Item.Entries (I).N);
      end loop;
   end Write_PN_Counter;

   procedure Read_PN_Counter
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Item   : out PN_Counter) with SPARK_Mode => Off
   is
      Kind  : CRDT.Serialization.Protocol_Kind;
      Total : Natural;
      Count : Natural;
   begin
      CRDT.Serialization.Read_Header (Stream, Kind, Total, Count);
      if Count > Item.Max_Actors then
         raise Constraint_Error with
           "PN_Counter stream has more entries than Max_Actors";
      end if;
      Item.Count := Count;
      for I in 1 .. Count loop
         declare
            Raw_A : Natural;
            Raw_P : Natural;
            Raw_N : Natural;
         begin
            CRDT.Serialization.Read_Natural (Kind, Stream, Raw_A);
            CRDT.Serialization.Read_Natural (Kind, Stream, Raw_P);
            CRDT.Serialization.Read_Natural (Kind, Stream, Raw_N);
            Item.Entries (I) := (Actor => Core.Replica_Id (Raw_A),
                                 P     => Counter_Range (Raw_P),
                                 N     => Counter_Range (Raw_N));
         end;
      end loop;
   end Read_PN_Counter;

end CRDT.Pn_Counters;
