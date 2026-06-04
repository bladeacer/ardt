with Ada.Exceptions;
with Ada.IO_Exceptions;
with Ada.Streams;
with CRDT.Core;
with CRDT.Core.LEB128;

package body CRDT.Serialization is

   use Ada.Streams;

   --  Decode a LEB128 Natural given a starter byte, reading
   --  continuation bytes from the stream as needed.
   procedure Decode_LEB128_From
     (Stream : not null access Root_Stream_Type'Class;
      B0     : Stream_Element;
      Value  : out Natural)
   is
      V     : Natural := 0;
      Shift : Natural := 0;
      B     : Stream_Element := B0;
   begin
      loop
         V := V + Natural (B and 127) * (2 ** Shift);
         Shift := Shift + 7;
         exit when (B and 128) = 0;
         Stream_Element'Read (Stream, B);
      end loop;
      Value := V;
   end Decode_LEB128_From;

   --  Decode a LEB128 Natural from the stream (no starter byte).
   procedure Decode_LEB128_Stream
     (Stream : not null access Root_Stream_Type'Class;
      Value  : out Natural) is
      B : Stream_Element;
   begin
      Stream_Element'Read (Stream, B);
      Decode_LEB128_From (Stream, B, Value);
   end Decode_LEB128_Stream;

   --  Try to read one byte; return False on End_Error.
   function Try_Read (Stream : not null access Root_Stream_Type'Class;
                      B      : out Stream_Element) return Boolean is
   begin
      Stream_Element'Read (Stream, B);
      return True;
   exception
      when Ada.IO_Exceptions.End_Error =>
         return False;
   end Try_Read;

   -----------------
   --  Read_Header --
   -----------------

   procedure Read_Header
     (Stream   : not null access Ada.Streams.Root_Stream_Type'Class;
      Kind     : out Protocol_Kind;
      Total    : out Natural;
      Count    : out Natural)
   is
      B1, B2, B3, B4 : Stream_Element;
   begin
      --  First byte: protocol version.
      if not Try_Read (Stream, B1) then
         raise Ada.IO_Exceptions.End_Error;
      end if;
      if B1 /= 2 then
         raise Constraint_Error with
           "Serialization.Read_Header: unsupported protocol version";
      end if;

      if not Try_Read (Stream, B2) then
         --  V2 with version-only payload
         Kind := Proto_V2;
         Total := 0;
         Count := 0;
         return;
      end if;

      if B2 /= 0 then
         Kind := Proto_V2;
         Decode_LEB128_From (Stream, B2, Total);
         Decode_LEB128_Stream (Stream, Count);
         return;
      end if;

      if not Try_Read (Stream, B3) then
         --  V2: Total = 0, truncated after B2
         Kind := Proto_V2;
         Total := 0;
         Count := 0;
         return;
      end if;

      if B3 /= 0 then
         Kind := Proto_V2;
         Total := 0;
         Decode_LEB128_From (Stream, B3, Count);
         return;
      end if;

      if not Try_Read (Stream, B4) then
         --  V2: Total = 0, Count = 0, stream ends at B3
         Kind := Proto_V2;
         Total := 0;
         Count := 0;
         return;
      end if;

      if B4 = 0 then
         Kind := Proto_V1;
         Natural'Read (Stream, Total);
         Natural'Read (Stream, Count);
      else
         Kind := Proto_V2;
         Total := 0;
         Count := 0;
      end if;
   end Read_Header;

   ------------------
   --  Read_Natural --
   ------------------

   procedure Read_Natural
     (Kind   : Protocol_Kind;
      Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Value  : out Natural)
   is
   begin
      case Kind is
         when Proto_V1 =>
            Natural'Read (Stream, Value);
         when Proto_V2 =>
            Core.LEB128.Decode (Stream, Value);
      end case;
   end Read_Natural;

end CRDT.Serialization;
