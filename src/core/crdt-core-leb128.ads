--  LEB128 variable-length integer encoding for compact wire protocol.
--  Small values (0-127) encode as a single byte instead of 4 (Natural'Write),
--  dramatically reducing bandwidth for the many single-digit fields
--  in CRDT serialization (protocol version, counts, lengths).
--
--  Two interfaces:
--    * Buffer-based (SPARK_Mode => On, provably safe)
--    * Stream-based (SPARK_Mode => Off, for backward compat with Ada.Streams)
--
--  Requirements traceability:
--  - HLR-PROTO-LEB128: LEB128 encode/decode for variable-length integers
with Ada.Streams;

package CRDT.Core.LEB128 with
  SPARK_Mode
is

   use Ada.Streams;

   subtype Byte_Array is Stream_Element_Array;

   --  Maximum LEB128 bytes needed for Natural (32-bit: ceil(31/7) = 5).
   Max_LEB128_Bytes : constant := 5;

   --  Encode Value as LEB128 bytes into Buffer starting at Index.
   --  Index is advanced past the written bytes.
   --  @param Buffer  Output byte buffer.
   --  @param Index   Start position; updated to one past the last written byte.
   --  @param Value   Integer to encode (0 .. Natural'Last).
   procedure Encode
     (Buffer : in out Byte_Array;
      Index  : in out Stream_Element_Offset;
      Value  : Natural) with
      SPARK_Mode,
      Pre  => Index in Buffer'Range,
      Post => Index > Index'Old;

   --  Decode a LEB128-encoded Natural from Buffer starting at Index.
   --  Index is advanced past the consumed bytes.
   --  @param Buffer  Input byte buffer.
   --  @param Index   Start position; updated to one past the last read byte.
   --  @param Value   Decoded integer.
   procedure Decode
     (Buffer : Byte_Array;
      Index  : in out Stream_Element_Offset;
      Value  : out Natural) with
      SPARK_Mode,
      Pre  => Index in Buffer'Range,
      Post => Index > Index'Old;

   --  Encode a Natural as LEB128 bytes to the stream.
   --  @param Stream  Target output stream.
   --  @param Value   Integer to encode (0 .. Natural'Last).
   procedure Encode
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Value  : Natural) with
     SPARK_Mode => Off;

   --  Decode a LEB128-encoded Natural from the stream.
   --  @param Stream  Source input stream.
   --  @param Value   Decoded integer.
   procedure Decode
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Value  : out Natural) with
     SPARK_Mode => Off;

end CRDT.Core.LEB128;
