package body CRDT.Core.LEB128 with
  SPARK_Mode
is

   use Ada.Streams;

   --------------------
   --  Encode (buffer) --
   --------------------

   procedure Encode
     (Buffer : in out Byte_Array;
      Index  : in out Stream_Element_Offset;
      Value  : Natural)
   is
      V : Natural := Value;
      T : Byte_Array (1 .. Max_LEB128_Bytes) := (others => 0);
      N : Stream_Element_Offset := 1;
   begin
      for I in 1 .. Max_LEB128_Bytes loop
         if V mod 128 = V then
            T (Stream_Element_Offset (I)) := Stream_Element (V);
            N := Stream_Element_Offset (I);
            exit;
         else
            T (Stream_Element_Offset (I)) :=
              Stream_Element (V mod 128 + 128);
            V := V / 128;
         end if;
      end loop;
      Buffer (Index .. Index + N - 1) := T (1 .. N);
      Index := Index + N;
   end Encode;

   --------------------
   --  Decode (buffer) --
   --------------------

   procedure Decode
     (Buffer : Byte_Array;
      Index  : in out Stream_Element_Offset;
      Value  : out Natural)
   is
      V     : Long_Long_Integer := 0;
      Shift : Natural := 0;
      N     : Stream_Element_Offset := 1;
   begin
      for I in 1 .. Max_LEB128_Bytes loop
         declare
            B : constant Stream_Element :=
              Buffer (Index + Stream_Element_Offset (I - 1));
         begin
            V := V
              + Long_Long_Integer (B and 127)
                * (Long_Long_Integer (2) ** Shift);
            N := Stream_Element_Offset (I);
            exit when (B and 128) = 0;
            Shift := Shift + 7;
         end;
      end loop;
      Index := Index + N;
      if V <= Long_Long_Integer (Natural'Last) then
         Value := Natural (V);
      else
         Value := Natural'Last;
      end if;
   end Decode;

   --------------------
   --  Encode (stream) --
   --------------------

   procedure Encode
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Value  : Natural)
   with SPARK_Mode => Off
   is
      Buf    : Byte_Array (1 .. Max_LEB128_Bytes);
      Buf_Idx : Stream_Element_Offset := 1;
   begin
      Encode (Buf, Buf_Idx, Value);
      for I in 1 .. Buf_Idx - 1 loop
         Stream_Element'Write (Stream, Buf (I));
      end loop;
   end Encode;

   --------------------
   --  Decode (stream) --
   --------------------

   procedure Decode
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Value  : out Natural)
   with SPARK_Mode => Off
   is
      Buf    : Byte_Array (1 .. Max_LEB128_Bytes);
      Buf_Idx : Stream_Element_Offset := 1;
      B      : Stream_Element;
   begin
      loop
         Stream_Element'Read (Stream, B);
         Buf (Buf_Idx) := B;
         exit when (B and 128) = 0 or Buf_Idx = Max_LEB128_Bytes;
         Buf_Idx := Buf_Idx + 1;
      end loop;
      Buf_Idx := 1;
      Decode (Buf, Buf_Idx, Value);
   end Decode;

end CRDT.Core.LEB128;
