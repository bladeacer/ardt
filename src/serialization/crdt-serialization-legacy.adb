package body CRDT.Serialization.Legacy is

   --------------------
   --  Read_Natural_V1 --
   --------------------

   procedure Read_Natural_V1
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Value  : out Natural)
   is
   begin
      Natural'Read (Stream, Value);
   end Read_Natural_V1;

end CRDT.Serialization.Legacy;
