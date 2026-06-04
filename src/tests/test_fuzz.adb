with CRDT.Test_Support; use CRDT.Test_Support;
with CRDT.Core;
with CRDT.Rga;
with CRDT.Lww_Element_Sets;
with Ada.Exceptions;
with Ada.IO_Exceptions;
with Ada.Numerics.Discrete_Random;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Text_IO; use Ada.Text_IO;

package body Test_Fuzz is

   procedure Run (RunR : in out Runner) is

   procedure Test_Fuzzing_Chaos is
      Max_RGA : constant Positive := 50;

      package RGA_Str is new CRDT.Rga (Character, Max_RGA);

      use Ada.Streams;
      use Ada.Streams.Stream_IO;

      ---------------------------
      --  1. Bit-Flipping Fuzz --
      ---------------------------
      procedure Fuzz_Bit_Flip is
         Src    : RGA_Str.RGA (Max_RGA);
         Good   : Ada.Streams.Stream_IO.File_Type;
         Buf    : Stream_Element_Array (1 .. 1024);
         Last   : Stream_Element_Offset;

         package Nat_Random is new Ada.Numerics.Discrete_Random (Natural);
         Gen    : Nat_Random.Generator;

         function Corrupt_Name (Iter : Natural) return String is
            Img : constant String := Natural'Image (Iter);
         begin
            return "/tmp/crdt_bitflip_" & Img (Img'First + 1 .. Img'Last) & ".bin";
         end;
      begin
         RGA_Str.Insert (Src, 1, (1, 1), 'A');
         RGA_Str.Insert_Bulk (Src, 2, (1, 2), "BCDEFG");

         Create (Good, Out_File, "/tmp/crdt_bitflip_good.bin");
         RGA_Str.RGA'Write (Stream (Good), Src);
         Close (Good);

         Open (Good, In_File, "/tmp/crdt_bitflip_good.bin");
         Ada.Streams.Stream_IO.Read (Good, Buf, Last);
         Close (Good);

         Nat_Random.Reset (Gen);

         for Iter in 1 .. 20 loop
            declare
               subtype SEO is Stream_Element_Offset;
               Corrupt    : Stream_Element_Array (SEO'(1) .. Last);
               Num_Bits   : constant Natural := Natural (Last) * 8;
               Flip_Bits  : constant Natural := Natural'Max (1,
                 (Num_Bits * (1 + (Nat_Random.Random (Gen) mod 5))) / 100);
               FName      : constant String := Corrupt_Name (Iter);
            begin
               Corrupt (SEO'(1) .. Last) := Buf (SEO'(1) .. Last);

               for F_Iter in 1 .. Flip_Bits loop
                  declare
                     B          : constant Natural := Nat_Random.Random (Gen) mod Num_Bits;
                     Byte_Idx   : constant SEO := SEO (B / 8 + 1);
                     Shift_Amt  : constant Natural := B mod 8;
                  begin
                     Corrupt (Byte_Idx) := Corrupt (Byte_Idx) xor
                       Stream_Element (2 ** Shift_Amt);
                  end;
               end loop;

               declare
                  BF   : Ada.Streams.Stream_IO.File_Type;
                  Dst  : RGA_Str.RGA (Max_RGA);
               begin
                  --  Write corrupt payload, read back, expect clean rejection
                  Create (BF, Out_File, FName);
                  Ada.Streams.Stream_IO.Write (BF, Corrupt);
                  Close (BF);

                  Open (BF, In_File, FName);
                  RGA_Str.RGA'Read (Stream (BF), Dst);
                  Close (BF);
               exception
                  when Constraint_Error =>
                     null;
                  when Ada.IO_Exceptions.End_Error =>
                     null;
                  when Ada.IO_Exceptions.Data_Error =>
                     null;
                  when E : others =>
                     RunR.Check(False, "Bit-flip fuzz: " &
                            Ada.Exceptions.Exception_Name (E) & " at iter" &
                            Natural'Image (Iter));
               end;
            end;
         end loop;

         RunR.Check(True, "Fuzz bit-flip: limit corrupt payloads all safely handled");
      end Fuzz_Bit_Flip;

      ----------------------------------
      --  2. Extreme Clock Skew Fuzz  --
      ----------------------------------
      procedure Fuzz_Clock_Skew is
         package LWW is new CRDT.Lww_Element_Sets (Integer, 100);
         A : LWW.LWW_Element_Set (100);
         B : LWW.LWW_Element_Set (100);
      begin
         --  Extreme future timestamps (near Natural'Last)
         for I in 1 .. 10 loop
            LWW.Add (A, I, (Stamp => Natural'Last - 100 + I, Node => 1));
         end loop;

         --  Extreme past timestamps
         for I in 1 .. 10 loop
            LWW.Add (B, I, (Stamp => 1, Node => 2));
         end loop;

         --  Merge past into future
         declare
            M : LWW.LWW_Element_Set (100) := A;
         begin
            LWW.Merge (M, B);
            RunR.Check(True,
              "Clock skew: merge future + past sets completes without error");
            for I in 1 .. 10 loop
               RunR.Check(LWW.Contains (M, I),
                 "Clock skew: element" & Natural'Image (I) & " survives merge");
            end loop;
         end;

         --  Merge future into past
         declare
            M : LWW.LWW_Element_Set (100) := B;
         begin
            LWW.Merge (M, A);
            RunR.Check(True,
              "Clock skew: merge past + future sets completes without error");
            for I in 1 .. 10 loop
               RunR.Check(LWW.Contains (M, I),
                 "Clock skew: element" & Natural'Image (I) & " survives reverse merge");
            end loop;
         end;

         --  Merge with mixed future/past in one set
         declare
            C : LWW.LWW_Element_Set (100);
         begin
            LWW.Add (C, 42, (Stamp => 500, Node => 3));
            LWW.Add (C, 99, (Stamp => Natural'Last, Node => 3));
            LWW.Merge (A, C);
            RunR.Check(LWW.Contains (A, 42) and LWW.Contains (A, 99),
              "Clock skew: elements with mixed extreme timestamps present after merge");
         end;

         RunR.Check(True, "Clock skew: extreme timestamp test passed");
      end Fuzz_Clock_Skew;

      -------------------------------------------
      --  3. Out-of-Order Delta Flood Fuzz      --
      -------------------------------------------
      procedure Fuzz_Ooo_Delta_Flood is
         package RGA_D is new CRDT.Rga (Character, 30);
         use type RGA_D.RGA;

         A       : RGA_D.RGA (30);
         B       : RGA_D.RGA (30);
         SV      : RGA_D.Replica_Max_Seq_Array (1 .. 10);
         Cnt     : Natural;
         No_Seen : constant RGA_D.Replica_Max_Seq_Array (1 .. 2) :=
           (1 => (Replica => 1, Max_Seq => 0),
            2 => (Replica => 2, Max_Seq => 0));
      begin
         RGA_D.Insert (A, 1, (1, 1), 'A');
         RGA_D.Insert (A, 2, (1, 2), 'B');
         RGA_D.Insert (A, 3, (1, 3), 'C');
         RGA_D.Insert (A, 4, (2, 1), 'D');
         RGA_D.Insert (A, 5, (1, 4), 'E');

         --  Sync A -> B using SV claiming B knows 0 items from replicas 1 and 2
         RGA_D.Sync_Delta (B, A, No_Seen, 2);
         RunR.Check(RGA_D.Size (B) = 5,
           "Ooo flood: initial sync gives 5 elements (got" &
           Natural'Image (RGA_D.Size (B)) & ")");

         --  Divergence: add more to A
         RGA_D.Insert (A, 6, (1, 5), 'F');
         RGA_D.Insert (A, 7, (1, 6), 'G');

         --  Duplicate delta: send the same SV twice
         RGA_D.Sync_Delta (B, A, No_Seen, 2);  --  real
         RGA_D.Sync_Delta (B, A, No_Seen, 2);  --  duplicate
         RunR.Check(RGA_D.Size (B) = 7,
           "Ooo flood: duplicate delta gives 7 elements (idempotent, got" &
           Natural'Image (RGA_D.Size (B)) & ")");

         --  Sync with an SV from a different replica that only saw its own 1 op
         declare
            C    : RGA_D.RGA (30);
            CS   : aliased RGA_D.Replica_Max_Seq_Array (1 .. 10);
            CCnt : Natural;
         begin
            RGA_D.Insert (C, 1, (3, 1), 'X');
            RGA_D.Compute_State_Vector (C, CS, CCnt);
            RGA_D.Sync_Delta (B, A, CS, CCnt);
            RunR.Check(RGA_D.Size (B) = 7,
              "Ooo flood: incomplete SV does not duplicate (got" &
              Natural'Image (RGA_D.Size (B)) & ")");
         end;

         --  Stale SV (B already has everything, re-request)
         RGA_D.Sync_Delta (B, A, No_Seen, 2);
         RunR.Check(RGA_D.Size (B) = 7,
           "Ooo flood: stale SV does not duplicate (got" &
           Natural'Image (RGA_D.Size (B)) & ")");

         RunR.Check(True, "Ooo delta flood: all duplications and clock skew handled");
      end Fuzz_Ooo_Delta_Flood;

   begin
      New_Line;
      Put_Line ("[Fuzzing Chaos]");
      Fuzz_Bit_Flip;
      Fuzz_Clock_Skew;
      Fuzz_Ooo_Delta_Flood;
      Put_Line ("[Fuzzing Chaos] done.");
   end Test_Fuzzing_Chaos;

   -----------------------------------------------
   --  Property-Based Fuzzer (10,000 runs)      --
   -----------------------------------------------
   --  @summary Property-based fuzzer: 10,000 iterations of LWW associativity with random Add/Remove sequences
   procedure Test_Property_Fuzzer is
      Max_LWW : constant Positive := 500;

      package LWW is new CRDT.Lww_Element_Sets (Integer, Max_LWW);

      use type LWW.LWW_Element_Set;

      package Nat_Random is new Ada.Numerics.Discrete_Random (Natural);
      Gen : Nat_Random.Generator;

      A : LWW.LWW_Element_Set (Max_LWW);
      B : LWW.LWW_Element_Set (Max_LWW);
      C : LWW.LWW_Element_Set (Max_LWW);
      Op : Natural;
      El : Integer;
   begin
      New_Line;
      Put_Line ("[Property Fuzzer]");

      for I in 1 .. 10000 loop
         Nat_Random.Reset (Gen, I);

         LWW.Clear (A);
         LWW.Clear (B);
         LWW.Clear (C);

         for J in 1 .. 50 loop
            El := (Nat_Random.Random (Gen) mod 100) + 1;
            Op := Nat_Random.Random (Gen) mod 2;
            if Op = 0 then
               LWW.Add (A, El, (Stamp => J * 10, Node => 1));
            else
               LWW.Remove (A, El, (Stamp => J * 10, Node => 1));
            end if;

            El := (Nat_Random.Random (Gen) mod 100) + 1;
            Op := Nat_Random.Random (Gen) mod 2;
            if Op = 0 then
               LWW.Add (B, El, (Stamp => J * 10 + 1, Node => 2));
            else
               LWW.Remove (B, El, (Stamp => J * 10 + 1, Node => 2));
            end if;

            El := (Nat_Random.Random (Gen) mod 100) + 1;
            Op := Nat_Random.Random (Gen) mod 2;
            if Op = 0 then
               LWW.Add (C, El, (Stamp => J * 10 + 2, Node => 3));
            else
               LWW.Remove (C, El, (Stamp => J * 10 + 2, Node => 3));
            end if;
         end loop;

          --  Check associativity: Merge(Merge(A,B),C) = Merge(A,Merge(B,C))
          declare
             M1 : LWW.LWW_Element_Set (Max_LWW) := A;
             M2 : LWW.LWW_Element_Set (Max_LWW) := A;
             BC : LWW.LWW_Element_Set (Max_LWW) := B;
             Assoc_Ok : Boolean := True;
          begin
             LWW.Merge (M1, B);
             LWW.Merge (M1, C);
             LWW.Merge (BC, C);
             LWW.Merge (M2, BC);
             for K in 1 .. 100 loop
                if LWW.Contains (M1, K) /= LWW.Contains (M2, K) then
                   Assoc_Ok := False;
                   exit;
                end if;
             end loop;
             RunR.Check(Assoc_Ok, "Fuzz associativity at iteration" & Natural'Image (I));
          end;

         if I mod 100 = 0 then
            Put_Line ("    fuzz iteration" & Natural'Image (I));
         end if;
      end loop;

      Put_Line ("[Property Fuzzer] done.");
   end Test_Property_Fuzzer;

   -----------------------------------------------
   --  Fuzzing Network Partitions               --
   -----------------------------------------------
   --  @summary Fuzzing network partitions: partition one node, verify divergence, then async rejoin converges
   procedure Test_Fuzzing_Network_Partitions is
      Max_LWW : constant Positive := 200;
      package LWW is new CRDT.Lww_Element_Sets (Integer, Max_LWW);

      S1 : LWW.LWW_Element_Set (Max_LWW);
      S2 : LWW.LWW_Element_Set (Max_LWW);
      S3 : LWW.LWW_Element_Set (Max_LWW);

      use type LWW.LWW_Element_Set;

      Stamp_1 : Natural := 0;
      Stamp_2 : Natural := 0;
      Stamp_3 : Natural := 0;

      package Nat_Random is new Ada.Numerics.Discrete_Random (Natural);
      Gen : Nat_Random.Generator;

      procedure Do_Op (S     : in out LWW.LWW_Element_Set;
                        Stamp : in out Natural;
                        Rep   : CRDT.Core.Replica_Id;
                        El    : Integer)
      is
         Op : constant Natural := Nat_Random.Random (Gen) mod 2;
      begin
         Stamp := Stamp + 1;
         if Op = 0 then
            LWW.Add (S, El, (Stamp, Rep));
         else
            LWW.Remove (S, El, (Stamp, Rep));
         end if;
      end Do_Op;

   begin
      New_Line;
      Put_Line ("[Fuzzing Network Partitions]");

      Nat_Random.Reset (Gen, 42);

      --  Phase 1: partition -- S3 is cut off for 50 ops
      for I in 1 .. 50 loop
         Do_Op (S1, Stamp_1, 1, I);
         Do_Op (S2, Stamp_2, 2, I);
         Do_Op (S3, Stamp_3, 3, I);

         --  S1 and S2 sync; S3 partitioned
         LWW.Merge (S1, S2);
         LWW.Merge (S2, S1);
      end loop;

      declare
         Divergent : Boolean := False;
      begin
         for I in 1 .. 50 loop
            if LWW.Contains (S1, I) /= LWW.Contains (S3, I) then
               Divergent := True;
               exit;
            end if;
         end loop;
         RunR.Check(Divergent,
                "S3 diverged during partition (expected, confirms partition happened)");
      end;

      --  Phase 2: async rejoin
      LWW.Merge (S1, S3);
      LWW.Merge (S3, S1);
      LWW.Merge (S2, S3);
      LWW.Merge (S3, S2);

      --  Converged? All three must agree on every element
      declare
         Conv_A : Boolean := True;
         Conv_B : Boolean := True;
         Conv_C : Boolean := True;
      begin
         for I in 1 .. 50 loop
            if LWW.Contains (S1, I) /= LWW.Contains (S2, I) then
               Conv_A := False;
            end if;
            if LWW.Contains (S2, I) /= LWW.Contains (S3, I) then
               Conv_B := False;
            end if;
            if LWW.Contains (S1, I) /= LWW.Contains (S3, I) then
               Conv_C := False;
            end if;
         end loop;
         RunR.Check(Conv_A, "S1 = S2 after async rejoin");
         RunR.Check(Conv_B, "S2 = S3 after async rejoin");
         RunR.Check(Conv_C, "S1 = S3 after async rejoin (transitive)");
      end;

      --  Repeat with RGA single-direction sync (avoids interleaving sensitivity)
      declare
         Max_RGA : constant Positive := 200;
         package RGA_Str is new CRDT.Rga (Character, Max_RGA);
         use type RGA_Str.RGA;

         R1   : RGA_Str.RGA (Max_RGA);
         R2   : RGA_Str.RGA (Max_RGA);
         R3   : RGA_Str.RGA (Max_RGA);

         Seq_1 : Natural := 0;
         Seq_2 : Natural := 0;
         Seq_3 : Natural := 0;

         procedure Append_Char
           (R   : in out RGA_Str.RGA;
            Seq : in out Natural;
            Rep : CRDT.Core.Replica_Id;
            Ch  : Character)
         is
         begin
            Seq := Seq + 1;
            RGA_Str.Insert (R, RGA_Str.Size (R) + 1, (Rep, Seq), Ch);
         end Append_Char;
      begin
         for I in 1 .. 50 loop
            Append_Char (R1, Seq_1, 1,
                          Character'Val ((Nat_Random.Random (Gen) mod 26) + 65));
            Append_Char (R2, Seq_2, 2,
                          Character'Val ((Nat_Random.Random (Gen) mod 26) + 65));
            Append_Char (R3, Seq_3, 3,
                          Character'Val ((Nat_Random.Random (Gen) mod 26) + 65));
         end loop;

         --  R1 and R2 sync (one phase, all-at-once)
         RGA_Str.Merge (R1, R2);
         RGA_Str.Merge (R2, R1);
         RunR.Check(R1 = R2, "RGA: R1 = R2 after partition sync");

         --  R3 catches up via async merge
         RGA_Str.Merge (R1, R3);
         RGA_Str.Merge (R3, R1);
         RGA_Str.Merge (R2, R3);
         RGA_Str.Merge (R3, R2);

         RunR.Check(R1 = R2, "RGA: R1 = R2 after async rejoin");
         RunR.Check(R2 = R3, "RGA: R2 = R3 after async rejoin");
         RunR.Check(R1 = R3, "RGA: R1 = R3 after async rejoin (transitive)");
      end;

      Put_Line ("[Fuzzing Network Partitions] done.");
   end Test_Fuzzing_Network_Partitions;

begin
   Test_Fuzzing_Chaos;
   Test_Property_Fuzzer;
   Test_Fuzzing_Network_Partitions;
end Run;
end Test_Fuzz;
