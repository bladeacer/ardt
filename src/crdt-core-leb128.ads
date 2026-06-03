with Ada.Streams;

package CRDT.Core.LEB128 is

   procedure Encode
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Value  : Natural);

   procedure Decode
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Value  : out Natural);

end CRDT.Core.LEB128;
