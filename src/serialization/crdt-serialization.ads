--  Protocol version router and canonical deserialization dispatcher.
--  Auto-detects V1 (fixed-width Natural) vs V2 (LEB128) wire formats
--  by inspecting the first 4 header bytes, then routes subsequent
--  field reads through the correct decoder.
--
--  This allows users of old library versions to serialise data that
--  newer library versions can seamlessly read and auto-migrate.
with Ada.Streams;

package CRDT.Serialization is

   type Protocol_Kind is (Proto_V1, Proto_V2);

   --  Read the wire-format header (version + Total + Count).
   --  Auto-detects V1 vs V2 by inspecting the first 4 bytes.
   --  After this call the stream is positioned just after the header,
   --  ready for item-by-item deserialization.
   --  Raises Constraint_Error for unsupported protocol versions.
   --  Raises End_Error on empty stream.
   procedure Read_Header
     (Stream   : not null access Ada.Streams.Root_Stream_Type'Class;
      Kind     : out Protocol_Kind;
      Total    : out Natural;
      Count    : out Natural);

   --  Read a single Natural from the stream using the detected
   --  protocol version's encoding (Natural'Read for V1, LEB128 for V2).
   procedure Read_Natural
     (Kind   : Protocol_Kind;
      Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Value  : out Natural);

end CRDT.Serialization;
