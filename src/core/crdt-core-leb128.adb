package body CRDT.Core.LEB128 is

   use Ada.Streams;

   procedure Encode
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Value  : Natural)
   is
      V : Natural := Value;
      B : Stream_Element;
   begin
      loop
         B := Stream_Element (V mod 128);
         V := V / 128;
         if V > 0 then
            B := B + 128;
         end if;
         Stream_Element'Write (Stream, B);
         exit when V = 0;
      end loop;
   end Encode;

   procedure Decode
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Value  : out Natural)
   is
      B     : Stream_Element;
      V     : Natural := 0;
      Shift : Natural := 0;
   begin
      loop
         Stream_Element'Read (Stream, B);
         V := V + Natural (B and 127) * (2 ** Shift);
         Shift := Shift + 7;
         exit when (B and 128) = 0;
      end loop;
      Value := V;
   end Decode;

end CRDT.Core.LEB128;
