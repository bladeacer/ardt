--  Legacy V1 fixed-width deserialization mechanisms.
--  Protocol V1 used 4-byte Natural'Read for all integer fields.
--  These routines are kept isolated here so they do not clutter
--  the main production code path.
--
--  The version router in CRDT.Serialization.Read_Header auto-detects
--  V1 vs V2 and dispatches field reads to the correct decoder,
--  so callers never need to touch this package directly.
with Ada.Streams;

package CRDT.Serialization.Legacy is

   --  Read a Natural encoded as a fixed 4-byte Natural'Write (V1 wire format).
   procedure Read_Natural_V1
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Value  : out Natural);

end CRDT.Serialization.Legacy;
