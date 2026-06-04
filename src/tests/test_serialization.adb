with CRDT.Test_Support; use CRDT.Test_Support;
with CRDT.Rga;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Text_IO; use Ada.Text_IO;

package body Test_Serialization is

   procedure Run (RunR : in out Runner) is

   procedure Test_Stream_Serialization is
      Max_RGA : constant Positive := 20;
      package RGA_Str is new CRDT.Rga (Character, Max_RGA);
      Src : RGA_Str.RGA (Max_RGA);
      Dst : RGA_Str.RGA (Max_RGA);
      use Ada.Streams.Stream_IO;
      F : Ada.Streams.Stream_IO.File_Type;
   begin
      New_Line;
      Put_Line ("[Serialization]");

      RGA_Str.Insert (Src, 1, (1, 1), 'H');
      RGA_Str.Insert (Src, 2, (1, 2), 'i');
      RGA_Str.Insert_Bulk (Src, 3, (2, 1), " Ada");

      -- Write to temp file
      Create (F, Out_File, "/tmp/crdt_serialize_test.bin");
      RGA_Str.RGA'Write (Stream (F), Src);
      Close (F);

      -- Read back
      Open (F, In_File, "/tmp/crdt_serialize_test.bin");
      RGA_Str.RGA'Read (Stream (F), Dst);
      Close (F);

      RunR.Check(RGA_Str.Size (Dst) = 6,
             "Deserialized size = 6 (got" &
             Natural'Image (RGA_Str.Size (Dst)) & ")");
      RunR.Check(RGA_Str.Get (Dst, 1) = 'H', "Deserialized Get (1) = 'H'");
      RunR.Check(RGA_Str.Get (Dst, 4) = 'A', "Deserialized Get (4) = 'A'");
      RunR.Check(RGA_Str.Get (Dst, 6) = 'a', "Deserialized Get (6) = 'a'");

      -- Verify equality of round-trip
      declare
         use type RGA_Str.RGA;
      begin
         RunR.Check(Src = Dst, "Round-trip serialization: Src = Dst");
      end;

      Put_Line ("[Serialization] done.");
   end Test_Stream_Serialization;

   procedure Test_Byte_Boundary is
      Max_RGA : constant Positive := 20;
      package RGA_Str is new CRDT.Rga (Character, Max_RGA);
      Src : RGA_Str.RGA (Max_RGA);
      Dst : RGA_Str.RGA (Max_RGA);
      use Ada.Streams.Stream_IO;
      F : Ada.Streams.Stream_IO.File_Type;
   begin
      New_Line;
      Put_Line ("[Byte-Boundary Round-tripping]");

      -- Empty RGA round-trip
      Create (F, Out_File, "/tmp/crdt_serialize_empty.bin");
      RGA_Str.RGA'Write (Stream (F), Src);
      Close (F);
      Open (F, In_File, "/tmp/crdt_serialize_empty.bin");
      RGA_Str.RGA'Read (Stream (F), Dst);
      Close (F);
      RunR.Check(RGA_Str.Size (Dst) = 0,
             "Empty RGA round-trip: size = 0");
      declare
         use type RGA_Str.RGA;
      begin
         RunR.Check(Src = Dst, "Empty RGA round-trip: Src = Dst");
      end;

      -- Null byte (Character'Val(0))
      RGA_Str.Insert (Src, 1, (1, 1), Character'Val (0));
      Create (F, Out_File, "/tmp/crdt_serialize_0.bin");
      RGA_Str.RGA'Write (Stream (F), Src);
      Close (F);
      Open (F, In_File, "/tmp/crdt_serialize_0.bin");
      RGA_Str.RGA'Read (Stream (F), Dst);
      Close (F);
      RunR.Check(RGA_Str.Get (Dst, 1) = Character'Val (0),
             "Null byte round-trip: Get(1) = 0");
      declare
         use type RGA_Str.RGA;
      begin
         RunR.Check(Src = Dst, "Null byte round-trip: Src = Dst");
      end;

      -- High byte (Character'Val(255))
      RGA_Str.Insert (Src, 2, (1, 2), Character'Val (255));
      Create (F, Out_File, "/tmp/crdt_serialize_255.bin");
      RGA_Str.RGA'Write (Stream (F), Src);
      Close (F);
      Open (F, In_File, "/tmp/crdt_serialize_255.bin");
      RGA_Str.RGA'Read (Stream (F), Dst);
      Close (F);
      RunR.Check(RGA_Str.Get (Dst, 1) = Character'Val (0),
             "High byte round-trip: Get(1) = 0 (unchanged)");
      RunR.Check(RGA_Str.Get (Dst, 2) = Character'Val (255),
             "High byte round-trip: Get(2) = 255");
      declare
         use type RGA_Str.RGA;
      begin
         RunR.Check(Src = Dst, "High byte round-trip: Src = Dst");
      end;

      Put_Line ("[Byte-Boundary Round-tripping] done.");
   end Test_Byte_Boundary;

   procedure Test_V1_Migration is
      Max_RGA : constant Positive := 30;
      package RGA_Str is new CRDT.Rga (Character, Max_RGA);
      Src     : RGA_Str.RGA (Max_RGA);
      Dst     : RGA_Str.RGA (Max_RGA);
      use Ada.Streams;
      use Ada.Streams.Stream_IO;
      F : Ada.Streams.Stream_IO.File_Type;
   begin
      New_Line;
      Put_Line ("[V1 Migration]");

      --  Build a representative RGA using a single Insert_Bulk (1 item)
      RGA_Str.Insert_Bulk (Src, 1, (1, 1), "ABCDE");

      --  Construct V1 wire format byte-by-byte.
      --  V1 layout: [Version:4][Total:4][Count:4]
      --             then per-item [Node_Id:8][Len:4][Deleted:1][Content:Len×1]
      declare
         subtype SEO is Stream_Element_Offset;
         Buf  : Stream_Element_Array (SEO'(1) .. 30);
         Idx  : SEO := SEO'(1);
         procedure WB (B : Stream_Element) is
         begin Buf (Idx) := B; Idx := Idx + 1; end WB;
         procedure WN (V : Natural) is
         begin
            --  Natural'Write on little-endian: LSB first
            WB (Stream_Element (V mod 256));
            WB (Stream_Element ((V / 256) mod 256));
            WB (Stream_Element ((V / 65536) mod 256));
            WB (Stream_Element ((V / 16777216) mod 256));
         end WN;
      begin
         --  Header
         WN (2);                     -- Protocol_Version = 2
         WN (5);                     -- Total = 5
         WN (1);                     -- Count = 1

         --  Single item: Node_Id (Replica => 1, Seq => 1)
         WN (1);  -- Replica
         WN (1);  -- Seq
         WN (5);  -- Len = 5
         WB (0);  -- Deleted = False

         --  Content: "ABCDE"
         WB (65); WB (66); WB (67); WB (68); WB (69);

         --  Write the V1 payload to file
         Create (F, Out_File, "/tmp/crdt_v1_migration.bin");
         Ada.Streams.Stream_IO.Write (F, Buf (1 .. Idx - 1));
         Close (F);
      end;

      --  Read back through auto-detecting version router
      Open (F, In_File, "/tmp/crdt_v1_migration.bin");
      RGA_Str.RGA'Read (Stream (F), Dst);
      Close (F);

      RunR.Check(RGA_Str.Size (Dst) = 5,
        "V1 migration: deserialized size = 5 (got" &
        Natural'Image (RGA_Str.Size (Dst)) & ")");
      RunR.Check(RGA_Str.Get (Dst, 1) = 'A', "V1 migration: Get(1) = 'A'");
      RunR.Check(RGA_Str.Get (Dst, 3) = 'C', "V1 migration: Get(3) = 'C'");
      RunR.Check(RGA_Str.Get (Dst, 5) = 'E', "V1 migration: Get(5) = 'E'");

      --  Also test empty V1 payload (Total=0, Count=0)
      declare
         subtype SEO is Stream_Element_Offset;
         Emp  : Stream_Element_Array (SEO'(1) .. 12);
         EmpI : SEO := SEO'(1);
         procedure WBE (B : Stream_Element) is
         begin Emp (EmpI) := B; EmpI := EmpI + 1; end WBE;
         procedure WNE (V : Natural) is
         begin
            WBE (Stream_Element (V mod 256));
            WBE (Stream_Element ((V / 256) mod 256));
            WBE (Stream_Element ((V / 65536) mod 256));
            WBE (Stream_Element ((V / 16777216) mod 256));
         end WNE;
         Empty_Dst : RGA_Str.RGA (Max_RGA);
      begin
         WNE (2); WNE (0); WNE (0);  -- Version=2, Total=0, Count=0
         Create (F, Out_File, "/tmp/crdt_v1_empty.bin");
         Ada.Streams.Stream_IO.Write (F, Emp (1 .. EmpI - 1));
         Close (F);
         Open (F, In_File, "/tmp/crdt_v1_empty.bin");
         RGA_Str.RGA'Read (Stream (F), Empty_Dst);
         Close (F);
         RunR.Check(RGA_Str.Size (Empty_Dst) = 0,
           "V1 migration: empty RGA deserialized size = 0");
      end;

      Put_Line ("[V1 Migration] done.");
   end Test_V1_Migration;

begin
   Test_Stream_Serialization;
   Test_Byte_Boundary;
   Test_V1_Migration;
end Run;
end Test_Serialization;
