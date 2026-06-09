with CRDT.Test_Support; use CRDT.Test_Support;
with CRDT.Pn_Counters;
with CRDT.Lww_Element_Sets;
with CRDT.Rga;
with CRDT.Core;
with CRDT.Core.LEB128;
with CRDT.Serialization;
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
      --             then per-item [Node_Id:8][Len:4][Deleted:1][Content:Len x 1]
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

   procedure Test_Migration_PN_Counter is
      use Ada.Streams;
      use Ada.Streams.Stream_IO;
      F : Ada.Streams.Stream_IO.File_Type;
      subtype SEO is Stream_Element_Offset;
      Buf  : Stream_Element_Array (SEO'(1) .. 40);
      Idx  : SEO := SEO'(1);
      procedure WB (B : Stream_Element) is
      begin Buf (Idx) := B; Idx := Idx + 1; end WB;
      procedure WN (V : Natural) is
      begin
         WB (Stream_Element (V mod 256));
         WB (Stream_Element ((V / 256) mod 256));
         WB (Stream_Element ((V / 65536) mod 256));
         WB (Stream_Element ((V / 16777216) mod 256));
      end WN;
   begin
      New_Line;
      Put_Line ("[Migration: PN_Counter V1->V2]");

      --  V1 header: [Version:4bytes][Total:4bytes][Count:4bytes]
      WN (2);  -- Version (B1..B4 = 02 00 00 00)
      WN (0);  -- Total = 0 (unused for PN_Counter)
      WN (2);  -- Count = 2
      --  Per-item: [Actor:4][P:4][N:4]
      WN (1);  WN (5);  WN (2);   -- Actor=1, P=5, N=2
      WN (2);  WN (3);  WN (0);   -- Actor=2, P=3, N=0

      Create (F, Out_File, "/tmp/crdt_migrate_pn_v1.bin");
      Ada.Streams.Stream_IO.Write (F, Buf (1 .. Idx - 1));
      Close (F);

      --  Read V1 data into counter
      declare
         C : CRDT.Pn_Counters.PN_Counter (Max_Actors => 5);
         D : CRDT.Pn_Counters.PN_Counter (Max_Actors => 5);
      begin
         Open (F, In_File, "/tmp/crdt_migrate_pn_v1.bin");
         CRDT.Pn_Counters.PN_Counter'Read (Stream (F), C);
         Close (F);

         RunR.Check (CRDT.Pn_Counters.Value (C) = 6,
           "PN V1 migration: value = 5+3-2 = 6 (got" &
           Integer'Image (CRDT.Pn_Counters.Value (C)) & ")");

         --  Write back as V2
         Create (F, Out_File, "/tmp/crdt_migrate_pn_v2.bin");
         CRDT.Pn_Counters.PN_Counter'Write (Stream (F), C);
         Close (F);

         --  Read V2 output back
         Open (F, In_File, "/tmp/crdt_migrate_pn_v2.bin");
         CRDT.Pn_Counters.PN_Counter'Read (Stream (F), D);
         Close (F);

         RunR.Check (CRDT.Pn_Counters.Value (C) = CRDT.Pn_Counters.Value (D),
           "PN V1->V2 round-trip: values match");
      end;

      --  Also test empty counter (Count=0)
      declare
         E : Stream_Element_Array (SEO'(1) .. 12);
         P : SEO := SEO'(1);
         procedure WBE (B : Stream_Element) is
         begin E (P) := B; P := P + 1; end WBE;
         procedure WNE (V : Natural) is
         begin
            WBE (Stream_Element (V mod 256));
            WBE (Stream_Element ((V / 256) mod 256));
            WBE (Stream_Element ((V / 65536) mod 256));
            WBE (Stream_Element ((V / 16777216) mod 256));
         end WNE;
         C : CRDT.Pn_Counters.PN_Counter (Max_Actors => 5);
         D : CRDT.Pn_Counters.PN_Counter (Max_Actors => 5);
      begin
         WNE (2); WNE (0); WNE (0);  -- Version=2, Total=0, Count=0
         Create (F, Out_File, "/tmp/crdt_migrate_pn_v1_empty.bin");
         Ada.Streams.Stream_IO.Write (F, E (1 .. P - 1));
         Close (F);

         Open (F, In_File, "/tmp/crdt_migrate_pn_v1_empty.bin");
         CRDT.Pn_Counters.PN_Counter'Read (Stream (F), C);
         Close (F);
         RunR.Check (CRDT.Pn_Counters.Value (C) = 0,
           "PN V1 migration: empty counter value = 0");
         RunR.Check (CRDT.Pn_Counters.Value (C) = CRDT.Pn_Counters.Value (D),
           "PN V1 migration: empty counter matches fresh");
      end;

      Put_Line ("[Migration: PN_Counter V1->V2] done.");
   end Test_Migration_PN_Counter;

    procedure Test_Migration_LWW_Roundtrip is
       Max_LWW : constant Positive := 10;
       package LWW is new CRDT.Lww_Element_Sets (Integer, Max_LWW);
       use Ada.Streams;
       use Ada.Streams.Stream_IO;
       F : Ada.Streams.Stream_IO.File_Type;
       Src : LWW.LWW_Element_Set (Max_LWW);
       Dst : LWW.LWW_Element_Set (Max_LWW);
       use type CRDT.Core.Lamport_Time;
       TS1 : constant CRDT.Core.Lamport_Time := (100, 1);
       TS2 : constant CRDT.Core.Lamport_Time := (200, 1);
    begin
       New_Line;
       Put_Line ("[Migration: LWW V1->V2]");

       --  V1 wire: [Ver:4][Add_Sz:4][Rem_Sz:4]
       --           per-entry: [Elem'Write][Stamp:4][Node:4]
       declare
          subtype SEO is Stream_Element_Offset;
          Buf  : Stream_Element_Array (SEO'(1) .. 40);
          Idx  : SEO := SEO'(1);
          procedure WB (B : Stream_Element) is
          begin Buf (Idx) := B; Idx := Idx + 1; end WB;
          procedure WN (V : Natural) is
          begin
             WB (Stream_Element (V mod 256));
             WB (Stream_Element ((V / 256) mod 256));
             WB (Stream_Element ((V / 65536) mod 256));
             WB (Stream_Element ((V / 16777216) mod 256));
          end WN;
       begin
          WN (2);    -- Version = 2 (in V1 4-byte encoding)
          WN (2);    -- Add_Size = 2
          WN (0);    -- Remove_Size = 0

          --  Entry 1: Element=42, Stamp=100, Node=1
          WN (42);
          WN (100);
          WN (1);

          --  Entry 2: Element=99, Stamp=200, Node=1
          WN (99);
          WN (200);
          WN (1);

          Create (F, Out_File, "/tmp/crdt_lww_v1.bin");
          Ada.Streams.Stream_IO.Write (F, Buf (1 .. Idx - 1));
          Close (F);
       end;

       --  Read V1 data
       declare
          C : LWW.LWW_Element_Set (Max_LWW);
          D : LWW.LWW_Element_Set (Max_LWW);
       begin
          Open (F, In_File, "/tmp/crdt_lww_v1.bin");
          LWW.LWW_Element_Set'Read (Stream (F), C);
          Close (F);

          RunR.Check (LWW.Contains (C, 42), "LWW V1 migration: contains 42");
          RunR.Check (LWW.Contains (C, 99), "LWW V1 migration: contains 99");
          RunR.Check (not LWW.Contains (C, 0), "LWW V1 migration: not contains 0");

          --  Write back as V2
          Create (F, Out_File, "/tmp/crdt_lww_v2.bin");
          LWW.LWW_Element_Set'Write (Stream (F), C);
          Close (F);

          --  Read V2 output back
          Open (F, In_File, "/tmp/crdt_lww_v2.bin");
          LWW.LWW_Element_Set'Read (Stream (F), D);
          Close (F);

          RunR.Check (LWW.Contains (D, 42), "LWW V1->V2 round-trip: contains 42");
          RunR.Check (LWW.Contains (D, 99), "LWW V1->V2 round-trip: contains 99");
          RunR.Check (not LWW.Contains (D, 0), "LWW V1->V2 round-trip: not contains 0");
       end;

       --  V2 round-trip
       LWW.Add (Src, 42, TS1);
       LWW.Add (Src, 99, TS2);

       Create (F, Out_File, "/tmp/crdt_lww_v2_rt.bin");
       LWW.LWW_Element_Set'Write (Stream (F), Src);
       Close (F);

       Open (F, In_File, "/tmp/crdt_lww_v2_rt.bin");
       LWW.LWW_Element_Set'Read (Stream (F), Dst);
       Close (F);

       RunR.Check (LWW.Contains (Dst, 42), "LWW V2 round-trip: contains 42");
       RunR.Check (LWW.Contains (Dst, 99), "LWW V2 round-trip: contains 99");
       RunR.Check (not LWW.Contains (Dst, 0), "LWW V2 round-trip: not contains 0");

       Put_Line ("[Migration: LWW V1->V2] done.");
    end Test_Migration_LWW_Roundtrip;

    procedure Test_Migrate_Header is
      use Ada.Streams;
      use Ada.Streams.Stream_IO;
      use CRDT.Serialization;
      F_In  : Ada.Streams.Stream_IO.File_Type;
      F_Out : Ada.Streams.Stream_IO.File_Type;
      subtype SEO is Stream_Element_Offset;
      Buf  : Stream_Element_Array (SEO'(1) .. 20);
      Idx  : SEO := SEO'(1);
      procedure WB (B : Stream_Element) is
      begin Buf (Idx) := B; Idx := Idx + 1; end WB;
      procedure WN (V : Natural) is
      begin
         WB (Stream_Element (V mod 256));
         WB (Stream_Element ((V / 256) mod 256));
         WB (Stream_Element ((V / 65536) mod 256));
         WB (Stream_Element ((V / 16777216) mod 256));
      end WN;
      Kind     : Protocol_Kind;
      Total    : Natural;
      Count    : Natural;
      V2_Total : Natural;
      V2_Count : Natural;
   begin
      New_Line;
      Put_Line ("[Migrate_Header]");

      --  Case 1: V1 -> V2
      --  V1 header: [Ver as Natural:4][Total as Natural:4][Count as Natural:4]
      Idx := SEO'(1);
      WN (2); WN (42); WN (7);   -- Ver=2, Total=42, Count=7

      Create (F_In, Out_File, "/tmp/crdt_v1_migrate_in.bin");
      Ada.Streams.Stream_IO.Write (F_In, Buf (1 .. Idx - 1));
      Close (F_In);

      Open  (F_In,  In_File, "/tmp/crdt_v1_migrate_in.bin");
      Create (F_Out, Out_File, "/tmp/crdt_v2_migrate_out.bin");

      Migrate_Header
        (Source => Stream (F_In),
         Dest   => Stream (F_Out),
         Kind   => Kind,
         Total  => Total,
         Count  => Count);

      RunR.Check (Kind = Proto_V1,
                  "Migrate_Header: detected V1");
      RunR.Check (Total = 42,
                  "Migrate_Header: Total = 42, got" & Natural'Image (Total));
      RunR.Check (Count = 7,
                  "Migrate_Header: Count = 7, got" & Natural'Image (Count));

      Close (F_In);
      Close (F_Out);

      Open (F_Out, In_File, "/tmp/crdt_v2_migrate_out.bin");
      Read_Header
        (Stream => Stream (F_Out),
         Kind   => Kind,
         Total  => V2_Total,
         Count  => V2_Count);
      RunR.Check (Kind = Proto_V2,
                  "Migrate_Header: output is V2");
      RunR.Check (V2_Total = 42,
                  "Migrate_Header: V2 Total = 42, got" &
                    Natural'Image (V2_Total));
      RunR.Check (V2_Count = 7,
                  "Migrate_Header: V2 Count = 7, got" &
                    Natural'Image (V2_Count));
      Close (F_Out);

      --  Case 2: V2 -> V2
      --  V2 header: [Version as LEB128][Total as LEB128][Count as LEB128]
      Idx := SEO'(1);
      WB (2);                         -- Protocol_Version = 2 (LEB128, 1 byte)
      WB (10);                        -- Total = 10 (LEB128, value < 128)
      WB (3);                         -- Count = 3 (LEB128, value < 128)

      Create (F_In, Out_File, "/tmp/crdt_v2_in.bin");
      Ada.Streams.Stream_IO.Write (F_In, Buf (1 .. Idx - 1));
      Close (F_In);

      Open  (F_In,  In_File, "/tmp/crdt_v2_in.bin");
      Create (F_Out, Out_File, "/tmp/crdt_v2_out.bin");

      Migrate_Header
        (Source => Stream (F_In),
         Dest   => Stream (F_Out),
         Kind   => Kind,
         Total  => Total,
         Count  => Count);

      RunR.Check (Kind = Proto_V2,
                  "Migrate_Header: detected V2 input");
      RunR.Check (Total = 10,
                  "Migrate_Header (V2): Total = 10, got" &
                    Natural'Image (Total));
      RunR.Check (Count = 3,
                  "Migrate_Header (V2): Count = 3, got" &
                    Natural'Image (Count));

      Close (F_In);
      Close (F_Out);

      Open (F_Out, In_File, "/tmp/crdt_v2_out.bin");
      Read_Header
        (Stream => Stream (F_Out),
         Kind   => Kind,
         Total  => V2_Total,
         Count  => V2_Count);
      RunR.Check (Kind = Proto_V2,
                  "Migrate_Header: V2->V2 output is V2");
      RunR.Check (V2_Total = 10,
                  "Migrate_Header: V2->V2 Total = 10, got" &
                    Natural'Image (V2_Total));
      RunR.Check (V2_Count = 3,
                  "Migrate_Header: V2->V2 Count = 3, got" &
                    Natural'Image (V2_Count));
      Close (F_Out);

      Put_Line ("[Migrate_Header] done.");
   end Test_Migrate_Header;

   procedure Test_V1_Backward_Compat is
      use Ada.Streams;
      use Ada.Streams.Stream_IO;
      use CRDT.Serialization;
      F : Ada.Streams.Stream_IO.File_Type;
      subtype SEO is Stream_Element_Offset;
      Buf  : Stream_Element_Array (SEO'(1) .. 100);
      Idx  : SEO := SEO'(1);
      procedure WB (B : Stream_Element) is
      begin Buf (Idx) := B; Idx := Idx + 1; end WB;
      procedure WN (V : Natural) is
      begin
         WB (Stream_Element (V mod 256));
         WB (Stream_Element ((V / 256) mod 256));
         WB (Stream_Element ((V / 65536) mod 256));
         WB (Stream_Element ((V / 16777216) mod 256));
      end WN;
      Kind     : CRDT.Serialization.Protocol_Kind;
      Total    : Natural;
      Count    : Natural;
   begin
      New_Line;
      Put_Line ("[V1 Backward Compat]");

      --  1. V1 empty payload (Total=0, Count=0)
      Idx := SEO'(1);
      WN (2); WN (0); WN (0);
      Create (F, Out_File, "/tmp/crdt_v1_empty_compat.bin");
      Ada.Streams.Stream_IO.Write (F, Buf (1 .. Idx - 1));
      Close (F);
      Open (F, In_File, "/tmp/crdt_v1_empty_compat.bin");
      Read_Header (Stream (F), Kind, Total, Count);
      RunR.Check (Kind = Proto_V1,
                  "V1 back-compat: empty payload detected as V1");
      RunR.Check (Total = 0,
                  "V1 back-compat: empty Total = 0, got" &
                    Natural'Image (Total));
      RunR.Check (Count = 0,
                  "V1 back-compat: empty Count = 0, got" &
                    Natural'Image (Count));
      Close (F);

      --  2. V1 maximum natural values
      Idx := SEO'(1);
      WN (2); WN (Natural'Last); WN (Natural'Last);
      Create (F, Out_File, "/tmp/crdt_v1_max_compat.bin");
      Ada.Streams.Stream_IO.Write (F, Buf (1 .. Idx - 1));
      Close (F);
      Open (F, In_File, "/tmp/crdt_v1_max_compat.bin");
      Read_Header (Stream (F), Kind, Total, Count);
      RunR.Check (Kind = Proto_V1,
                  "V1 back-compat: max payload detected as V1");
      RunR.Check (Total = Natural'Last,
                  "V1 back-compat: max Total, got" &
                    Natural'Image (Total));
      RunR.Check (Count = Natural'Last,
                  "V1 back-compat: max Count, got" &
                    Natural'Image (Count));
      Close (F);

      --  3. V2 protocol field matches constant
      --  Core.Protocol_Version = 2, which is always the first LEB128 byte
      Idx := SEO'(1);
      WB (2); WB (0); WB (0);  -- V2: Version=2, Total=0, Count=0
      Create (F, Out_File, "/tmp/crdt_v2_proto_check.bin");
      Ada.Streams.Stream_IO.Write (F, Buf (1 .. Idx - 1));
      Close (F);
      Open (F, In_File, "/tmp/crdt_v2_proto_check.bin");
      Read_Header (Stream (F), Kind, Total, Count);
      RunR.Check (Kind = Proto_V2,
                  "V1 back-compat: V2 short header detected as V2");
      Close (F);

      --  4. V1 multi-item RGA payload: 2 items
      declare
         Max_RGA : constant Positive := 30;
         package RGA_Str is new CRDT.Rga (Character, Max_RGA);
         Dst : RGA_Str.RGA (Max_RGA);
      begin
         Idx := SEO'(1);
         WN (2); WN (3); WN (2);  -- Ver=2, Total=3, Count=2
         -- Item 1: Node_Id=(1,1), Len=2, Content="AB"
         WN (1); WN (1); WN (2); WB (0);
         WB (65); WB (66);
         -- Item 2: Node_Id=(1,2), Len=1, Content="C"
         WN (1); WN (2); WN (1); WB (0);
         WB (67);
         Create (F, Out_File, "/tmp/crdt_v1_multi_rga.bin");
         Ada.Streams.Stream_IO.Write (F, Buf (1 .. Idx - 1));
         Close (F);
         Open (F, In_File, "/tmp/crdt_v1_multi_rga.bin");
         RGA_Str.RGA'Read (Stream (F), Dst);
         Close (F);
         RunR.Check (RGA_Str.Size (Dst) = 3,
                     "V1 back-compat: multi-item RGA size = 3, got" &
                       Natural'Image (RGA_Str.Size (Dst)));
         RunR.Check (RGA_Str.Get (Dst, 1) = 'A',
                     "V1 back-compat: multi-item RGA Get(1)='A'");
         RunR.Check (RGA_Str.Get (Dst, 3) = 'C',
                     "V1 back-compat: multi-item RGA Get(3)='C'");
      end;

      --  5. V1 LWW with remove entries
      declare
         package LWW is new CRDT.Lww_Element_Sets (Integer, 20);
         S : LWW.LWW_Element_Set (Capacity => 20);
      begin
         Idx := SEO'(1);
         WN (2); WN (1); WN (1);  -- Ver=2, Add_Size=1, Remove_Size=1
         -- 1 add entry: Element=42, Stamp=100, Node=1
         WN (42); WN (100); WN (1);
         -- 1 remove entry: Element=42, Stamp=200, Node=1
         WN (42); WN (200); WN (1);
         Create (F, Out_File, "/tmp/crdt_v1_lww_remove.bin");
         Ada.Streams.Stream_IO.Write (F, Buf (1 .. Idx - 1));
         Close (F);
         Open (F, In_File, "/tmp/crdt_v1_lww_remove.bin");
         LWW.LWW_Element_Set'Read (Stream (F), S);
         Close (F);
         RunR.Check (not LWW.Contains (S, 42),
                     "V1 back-compat: LWW remove, not contains 42");
      end;

       Put_Line ("[V1 Backward Compat] done.");
    end Test_V1_Backward_Compat;

    procedure Test_LEB128 is
       use Ada.Streams;
       use Ada.Streams.Stream_IO;
       Values : constant array (Positive range <>) of Natural :=
         (0, 1, 127, 128, 16383, 16384, 2097151, 2097152, Natural'Last);
       Names : constant array (Values'Range) of String (1 .. 17) :=
         ("zero             ",
          "one              ",
          "max single byte  ",
          "min two bytes    ",
          "max two bytes    ",
          "min three bytes  ",
          "max three bytes  ",
          "min four bytes   ",
          "Natural'Last     ");
       F : Ada.Streams.Stream_IO.File_Type;
       D : Natural;
    begin
       New_Line;
       Put_Line ("[LEB128 Encode/Decode]");
       for I in Values'Range loop
          Create (F, Out_File, "/tmp/crdt_leb128_test.bin");
          CRDT.Core.LEB128.Encode (Stream (F), Values (I));
          Close (F);
          Open (F, In_File, "/tmp/crdt_leb128_test.bin");
          CRDT.Core.LEB128.Decode (Stream (F), D);
          Close (F);
          RunR.Check (D = Values (I), "LEB128 round-trip: " & Names (I));
       end loop;
       Put_Line ("[LEB128 Encode/Decode] done.");
    end Test_LEB128;

begin
    Test_Stream_Serialization;
    Test_Byte_Boundary;
    Test_LEB128;
    Test_V1_Migration;
    Test_Migration_PN_Counter;
    Test_Migration_LWW_Roundtrip;
    Test_Migrate_Header;
    Test_V1_Backward_Compat;
end Run;
end Test_Serialization;
