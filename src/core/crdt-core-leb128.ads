--  LEB128 variable-length integer encoding for compact wire protocol.
--  Small values (0-127) encode as a single byte instead of 4 (Natural'Write),
--  dramatically reducing bandwidth for the many single-digit fields
--  in CRDT serialization (protocol version, counts, lengths).
with Ada.Streams;

package CRDT.Core.LEB128 is

   --  Encode a Natural as LEB128 bytes to the stream.
   --  @param Stream  Target output stream.
   --  @param Value   Integer to encode (0 .. Natural'Last).
   procedure Encode
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Value  : Natural);

   --  Decode a LEB128-encoded Natural from the stream.
   --  @param Stream  Source input stream.
   --  @param Value   Decoded integer.
   procedure Decode
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Value  : out Natural);

end CRDT.Core.LEB128;
