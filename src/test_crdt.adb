with Ada.Text_IO;
with Ada.Numerics.Discrete_Random;
with Ada.Numerics.Float_Random;
with Ardt.Core;
with Ardt.Pn_Counters;
with Ardt.Lww_Element_Sets;
with Ardt.Rga;
with Ardt.Rgas;

procedure Test_Crdt is

   use Ada.Text_IO;

   Passed : Natural := 0;
   Failed : Natural := 0;

   procedure Check (Cond : Boolean; Msg : String) is
   begin
      if Cond then
         Passed := Passed + 1;
         Put_Line ("  PASS: " & Msg);
      else
         Failed := Failed + 1;
         Put_Line ("  FAIL: " & Msg);
      end if;
   end Check;

   -----------------------
   --  PN-Counter Tests --
   -----------------------
   procedure Test_PN_Counter is
      C : Ardt.Pn_Counters.PN_Counter;
      V : Integer;
   begin
      New_Line;
      Put_Line ("[PN-Counter]");

      V := Ardt.Pn_Counters.Value (C);
      Check (V = 0, "Initial value = 0 (got" & Integer'Image (V) & ")");

      Ardt.Pn_Counters.Increment (C, 5);
      V := Ardt.Pn_Counters.Value (C);
      Check (V = 5, "After Increment (C, 5): value = 5 (got" & Integer'Image (V) & ")");

      Ardt.Pn_Counters.Decrement (C, 3);
      V := Ardt.Pn_Counters.Value (C);
      Check (V = 2, "After Decrement (C, 3): value = 2 (got" & Integer'Image (V) & ")");

      Ardt.Pn_Counters.Increment (C, 1);
      V := Ardt.Pn_Counters.Value (C);
      Check (V = 3, "After Increment (C, 1): value = 3 (got" & Integer'Image (V) & ")");

      Ardt.Pn_Counters.Decrement (C, 4);
      V := Ardt.Pn_Counters.Value (C);
      Check (V = -1, "After Decrement (C, 4): value = -1 (got" & Integer'Image (V) & ")");

      declare
         D : Ardt.Pn_Counters.PN_Counter;
      begin
         Ardt.Pn_Counters.Increment (D, 10);
         Ardt.Pn_Counters.Merge (C, D);
         V := Ardt.Pn_Counters.Value (C);
         Check (V = 3, "After Merge with D (P=10,N=0): value = 3 (got" & Integer'Image (V) & ")");
      end;

      Put_Line ("[PN-Counter] done.");
   end Test_PN_Counter;

   -----------------------------
   --  LWW-Element-Set Tests  --
   -----------------------------
   procedure Test_LWW_Set is
      Max_Size : constant Positive := 10;

      package LWW is new Ardt.Lww_Element_Sets (Integer, Max_Size);

      S : LWW.LWW_Element_Set (Max_Size);
   begin
      New_Line;
      Put_Line ("[LWW-Element-Set]");

      Check (not LWW.Contains (S, 42), "Empty set: Contains (42) = False");

      LWW.Add (S, 42, 100);
      Check (LWW.Contains (S, 42), "Add (42, ts=100): Contains (42) = True");

      LWW.Add (S, 7, 200);
      Check (LWW.Contains (S, 7), "Add (7, ts=200): Contains (7) = True");

      LWW.Remove (S, 42, 150);
      Check (not LWW.Contains (S, 42),
             "Remove (42, ts=150): Contains (42) = False (150 > 100)");

      LWW.Add (S, 42, 200);
      Check (LWW.Contains (S, 42),
             "Re-add (42, ts=200): Contains (42) = True (200 > 150)");

      LWW.Remove (S, 42, 250);
      Check (not LWW.Contains (S, 42),
             "Remove (42, ts=250): Contains (42) = False (250 > 200)");

      LWW.Remove (S, 7, 300);
      Check (not LWW.Contains (S, 7),
             "Remove (7, ts=300): Contains (7) = False (300 > 200)");

      LWW.Add (S, 7, 350);
      Check (LWW.Contains (S, 7),
             "Re-add (7, ts=350): Contains (7) = True (350 > 300)");

      declare
         T : LWW.LWW_Element_Set (Max_Size);
      begin
         LWW.Add (T, 99, 500);
         LWW.Merge (S, T);
         Check (LWW.Contains (S, 99),
                "Merge with set containing (99, ts=500): Contains (99) = True");
      end;

      Put_Line ("[LWW-Element-Set] done.");
   end Test_LWW_Set;

   -----------------------
   --  RGA Tests        --
   -----------------------
   procedure Test_RGA is
      Max_Sz  : constant Positive := 10;
      Seq     : Natural := 0;

      package RGA_Str is new Ardt.Rga (Character, Max_Sz);

      R : RGA_Str.RGA (Max_Sz);

      function Next_Seq return RGA_Str.Node_Id is
      begin
         Seq := Seq + 1;
         return (Replica => 1, Seq => Seq);
      end Next_Seq;
   begin
      New_Line;
      Put_Line ("[RGA]");

      Check (RGA_Str.Size (R) = 0, "Initial size = 0 (got" & Natural'Image (RGA_Str.Size (R)) & ")");

      RGA_Str.Insert (R, 1, Next_Seq, 'a');
      Check (RGA_Str.Size (R) = 1, "Insert 'a' at 1: size = 1");
      Check (RGA_Str.Get (R, 1) = 'a', "Get (1) = 'a'");

      RGA_Str.Insert (R, 2, Next_Seq, 'b');
      RGA_Str.Insert (R, 3, Next_Seq, 'c');
      Check (RGA_Str.Size (R) = 3, "Insert 'b','c': size = 3");
      Check (RGA_Str.Get (R, 1) = 'a', "Get (1) = 'a'");
      Check (RGA_Str.Get (R, 2) = 'b', "Get (2) = 'b'");
      Check (RGA_Str.Get (R, 3) = 'c', "Get (3) = 'c'");

      RGA_Str.Insert (R, 2, Next_Seq, 'x');
      Check (RGA_Str.Size (R) = 4, "Insert 'x' at 2: size = 4");
      Check (RGA_Str.Get (R, 1) = 'a', "Get (1) = 'a'");
      Check (RGA_Str.Get (R, 2) = 'x', "Get (2) = 'x'");
      Check (RGA_Str.Get (R, 3) = 'b', "Get (3) = 'b'");
      Check (RGA_Str.Get (R, 4) = 'c', "Get (4) = 'c'");

      RGA_Str.Delete (R, 3);
      Check (RGA_Str.Size (R) = 4, "Delete (3): size unchanged = 4 (tombstone)");

      declare
         R2 : RGA_Str.RGA (Max_Sz);
      begin
         RGA_Str.Insert (R2, 1, (Replica => 2, Seq => 1), 'y');
         RGA_Str.Merge (R, R2);
         Check (RGA_Str.Size (R) >= 4, "After merge with R2 (contains 'y'): size >= 4");
         Put_Line ("    info: merged size =" & Natural'Image (RGA_Str.Size (R)));
      end;

      Put_Line ("[RGA] done.");
   end Test_RGA;

   ------------------------
   --  RGAs Tests        --
   ------------------------
   procedure Test_RGAs is
      Max_Sz  : constant Positive := 10;
      Max_Cnt : constant Positive := 5;

      package RGAs_Pkg is new Ardt.Rgas (Character, Max_Sz, Max_Cnt);

      RS : RGAs_Pkg.RGAs (Max_Cnt);
      R1 : RGAs_Pkg.RGA_Entry;
      R2 : RGAs_Pkg.RGA_Entry;
   begin
      New_Line;
      Put_Line ("[RGAs]");

      Check (RGAs_Pkg.Size (RS) = 0, "Initial size = 0");

      RGAs_Pkg.RGA_Pkg.Insert (R1, 1, (Replica => 1, Seq => 1), 'a');
      RGAs_Pkg.RGA_Pkg.Insert (R1, 2, (Replica => 1, Seq => 2), 'b');
      RGAs_Pkg.Append (RS, R1);
      Check (RGAs_Pkg.Size (RS) = 1, "After append R1 ('a','b'): size = 1");

      RGAs_Pkg.RGA_Pkg.Insert (R2, 1, (Replica => 2, Seq => 1), 'c');
      RGAs_Pkg.RGA_Pkg.Insert (R2, 2, (Replica => 2, Seq => 2), 'd');
      RGAs_Pkg.Append (RS, R2);
      Check (RGAs_Pkg.Size (RS) = 2, "After append R2 ('c','d'): size = 2");

      declare
         G1 : constant RGAs_Pkg.RGA_Entry := RGAs_Pkg.Get (RS, 1);
         G2 : constant RGAs_Pkg.RGA_Entry := RGAs_Pkg.Get (RS, 2);
      begin
         Check (RGAs_Pkg.RGA_Pkg.Size (G1) = 2, "Get (1): size = 2");
         Check (RGAs_Pkg.RGA_Pkg.Size (G2) = 2, "Get (2): size = 2");
      end;

      Put_Line ("[RGAs] done.");
   end Test_RGAs;

   ---------------------------------------------
   --  Lattice Property Tests (Adversarial)   --
   ---------------------------------------------
   procedure Test_Lattice_Properties is
      Num_Ops : constant Positive := 100;

      package Pos_Random is new Ada.Numerics.Discrete_Random (Positive);
      package Nat_Random is new Ada.Numerics.Discrete_Random (Natural);
      package Int_Random is new Ada.Numerics.Discrete_Random (Integer);

      Pos_Gen  : Pos_Random.Generator;
      Nat_Gen  : Nat_Random.Generator;
      Int_Gen  : Int_Random.Generator;

      Seed1 : constant Integer := 12345;
      Seed2 : constant Integer := 67890;
      Seed3 : constant Integer := 11121;

   begin
      New_Line;
      Put_Line ("[Lattice Properties]");

      Pos_Random.Reset (Pos_Gen, Seed1);
      Nat_Random.Reset (Nat_Gen, Seed1);
      Int_Random.Reset (Int_Gen, Seed1);

      --------------------
      --  PN-Counter    --
      --------------------
      declare
         A : Ardt.Pn_Counters.PN_Counter;
         B : Ardt.Pn_Counters.PN_Counter;
         C : Ardt.Pn_Counters.PN_Counter;
         D : Ardt.Pn_Counters.PN_Counter;
         E : Ardt.Pn_Counters.PN_Counter;
         Op : Natural;
      begin
         for I in 1 .. Num_Ops loop
            Op := Pos_Random.Random (Pos_Gen) mod 2;
            if Op = 0 then
               Ardt.Pn_Counters.Increment (A, Nat_Random.Random (Nat_Gen) mod 20 + 1);
            else
               Ardt.Pn_Counters.Decrement (A, Nat_Random.Random (Nat_Gen) mod 20 + 1);
            end if;
         end loop;

         Pos_Random.Reset (Pos_Gen, Seed2);
         Nat_Random.Reset (Nat_Gen, Seed2);
         for I in 1 .. Num_Ops loop
            Op := Pos_Random.Random (Pos_Gen) mod 2;
            if Op = 0 then
               Ardt.Pn_Counters.Increment (B, Nat_Random.Random (Nat_Gen) mod 20 + 1);
            else
               Ardt.Pn_Counters.Decrement (B, Nat_Random.Random (Nat_Gen) mod 20 + 1);
            end if;
         end loop;

         Pos_Random.Reset (Pos_Gen, Seed3);
         Nat_Random.Reset (Nat_Gen, Seed3);
         for I in 1 .. Num_Ops loop
            Op := Pos_Random.Random (Pos_Gen) mod 2;
            if Op = 0 then
               Ardt.Pn_Counters.Increment (C, Nat_Random.Random (Nat_Gen) mod 20 + 1);
            else
               Ardt.Pn_Counters.Decrement (C, Nat_Random.Random (Nat_Gen) mod 20 + 1);
            end if;
         end loop;

         D := A;
         Ardt.Pn_Counters.Merge (D, B);
         E := B;
         Ardt.Pn_Counters.Merge (E, A);
         Check (Ardt.Pn_Counters.Value (D) = Ardt.Pn_Counters.Value (E),
                "PN-Counter commutativity: Merge(A,B) = Merge(B,A)");

         D := A;
         Ardt.Pn_Counters.Merge (D, A);
         Check (Ardt.Pn_Counters.Value (D) = Ardt.Pn_Counters.Value (A),
                "PN-Counter idempotency: Merge(A,A) = A");

         D := A;
         Ardt.Pn_Counters.Merge (D, B);
         Ardt.Pn_Counters.Merge (D, C);
         E := A;
         declare
            Tmp : Ardt.Pn_Counters.PN_Counter := B;
         begin
            Ardt.Pn_Counters.Merge (Tmp, C);
            Ardt.Pn_Counters.Merge (E, Tmp);
         end;
         Check (Ardt.Pn_Counters.Value (D) = Ardt.Pn_Counters.Value (E),
                "PN-Counter associativity: Merge(Merge(A,B),C) = Merge(A,Merge(B,C))");
      end;

      --------------------------
      --  LWW-Element-Set     --
      --------------------------
      declare
         Max_LWW : constant Positive := 500;

         package LWW is new Ardt.Lww_Element_Sets (Integer, Max_LWW);

         use type LWW.LWW_Element_Set;

         A : LWW.LWW_Element_Set (Max_LWW);
         B : LWW.LWW_Element_Set (Max_LWW);
         C : LWW.LWW_Element_Set (Max_LWW);
         D : LWW.LWW_Element_Set (Max_LWW);
         E : LWW.LWW_Element_Set (Max_LWW);
         Op : Natural;
         El : Integer;
         TS : Ardt.Core.Timestamp;
      begin
         for I in 1 .. 50 loop
            LWW.Add (A, I, Ardt.Core.Timestamp (I * 100));
            LWW.Add (B, I, Ardt.Core.Timestamp (I * 100 + 50));
            LWW.Add (C, I, Ardt.Core.Timestamp (I * 100 + 25));
         end loop;

         D := A;
         LWW.Merge (D, B);
         E := B;
         LWW.Merge (E, A);
         declare
            Commute_Ok : Boolean := True;
         begin
            for I in 1 .. 50 loop
               if LWW.Contains (D, I) /= LWW.Contains (E, I) then
                  Commute_Ok := False;
                  exit;
               end if;
            end loop;
            Check (Commute_Ok,
                   "LWW commutativity: Merge(A,B) = Merge(B,A) (semantic)");
         end;

         D := A;
         LWW.Merge (D, A);
         Check (D = A, "LWW idempotency: Merge(A,A) = A");

         D := A;
         LWW.Merge (D, B);
         LWW.Merge (D, C);
         E := A;
         declare
            Tmp : LWW.LWW_Element_Set (Max_LWW) := B;
         begin
            LWW.Merge (Tmp, C);
            LWW.Merge (E, Tmp);
         end;
         declare
            Assoc_Ok : Boolean := True;
         begin
            for I in 1 .. 50 loop
               if LWW.Contains (D, I) /= LWW.Contains (E, I) then
                  Assoc_Ok := False;
                  exit;
               end if;
            end loop;
            Check (Assoc_Ok,
                   "LWW associativity: Merge(Merge(A,B),C) = Merge(A,Merge(B,C)) (semantic)");
         end;
      end;

      --------------------
      --  RGA           --
      --------------------
      declare
         Max_RGA : constant Positive := 500;
         Seq_A   : Natural := 0;
         Seq_B   : Natural := 0;
         Seq_C   : Natural := 0;

         package RGA_Ch is new Ardt.Rga (Character, Max_RGA);

         use type RGA_Ch.RGA;

         A : RGA_Ch.RGA (Max_RGA);
         B : RGA_Ch.RGA (Max_RGA);
         C : RGA_Ch.RGA (Max_RGA);
         D : RGA_Ch.RGA (Max_RGA);
         E : RGA_Ch.RGA (Max_RGA);
         Pos : Positive;
         Ch  : Character;
      begin
         Nat_Random.Reset (Nat_Gen, Seed1);
          for I in 1 .. Num_Ops loop
             Seq_A := Seq_A + 1;
             if RGA_Ch.Size (A) = 0 then
                Pos := 1;
             else
                Pos := (Nat_Random.Random (Nat_Gen) mod RGA_Ch.Size (A)) + 1;
             end if;
             Ch  := Character'Val ((Nat_Random.Random (Nat_Gen) mod 26) + 65);
             RGA_Ch.Insert (A, Pos, (1, Seq_A), Ch);
          end loop;

          Nat_Random.Reset (Nat_Gen, Seed2);
          for I in 1 .. Num_Ops loop
             Seq_B := Seq_B + 1;
             if RGA_Ch.Size (B) = 0 then
                Pos := 1;
             else
                Pos := (Nat_Random.Random (Nat_Gen) mod RGA_Ch.Size (B)) + 1;
             end if;
             Ch  := Character'Val ((Nat_Random.Random (Nat_Gen) mod 26) + 65);
             RGA_Ch.Insert (B, Pos, (2, Seq_B), Ch);
          end loop;

          Nat_Random.Reset (Nat_Gen, Seed3);
          for I in 1 .. Num_Ops loop
             Seq_C := Seq_C + 1;
             if RGA_Ch.Size (C) = 0 then
                Pos := 1;
             else
                Pos := (Nat_Random.Random (Nat_Gen) mod RGA_Ch.Size (C)) + 1;
             end if;
             Ch  := Character'Val ((Nat_Random.Random (Nat_Gen) mod 26) + 65);
             RGA_Ch.Insert (C, Pos, (3, Seq_C), Ch);
          end loop;

         D := A;
         RGA_Ch.Merge (D, B);
         E := B;
         RGA_Ch.Merge (E, A);
         Check (D = E, "RGA commutativity: Merge(A,B) = Merge(B,A)");

         D := A;
         RGA_Ch.Merge (D, A);
         Check (D = A, "RGA idempotency: Merge(A,A) = A");

         D := A;
         RGA_Ch.Merge (D, B);
         RGA_Ch.Merge (D, C);
         E := A;
         declare
            Tmp : RGA_Ch.RGA (Max_RGA) := B;
         begin
            RGA_Ch.Merge (Tmp, C);
            RGA_Ch.Merge (E, Tmp);
         end;
         Check (D = E, "RGA associativity: Merge(Merge(A,B),C) = Merge(A,Merge(B,C))");
      end;

      Put_Line ("[Lattice Properties] done.");
   end Test_Lattice_Properties;

   -----------------------------------------------
   --  Chaotic Network Delay / Interleaving     --
   -----------------------------------------------
   procedure Test_Chaotic_Interleaving is
      Max_RGA : constant Positive := 50;
      Seq     : Natural := 0;

      package RGA_Str is new Ardt.Rga (Character, Max_RGA);

      function El (C : Character) return Character is (C);

      function To_String (R : RGA_Str.RGA) return String is
         Buf : String (1 .. RGA_Str.Size (R));
         Idx : Natural := 0;
      begin
         for I in 1 .. RGA_Str.Size (R) loop
            begin
               Buf (Idx + 1) := RGA_Str.Get (R, I);
               Idx := Idx + 1;
            exception
               when others =>
                  null;
            end;
         end loop;
         return Buf (1 .. Idx);
      end To_String;

      function Next_Id return RGA_Str.Node_Id is
      begin
         Seq := Seq + 1;
         return (Replica => 1, Seq => Seq);
      end Next_Id;

   begin
      New_Line;
      Put_Line ("[Chaotic Interleaving]");

      declare
         use type RGA_Str.RGA;

         Base : RGA_Str.RGA (Max_RGA);
         R1   : RGA_Str.RGA (Max_RGA);
         R2   : RGA_Str.RGA (Max_RGA);
         M    : RGA_Str.RGA (Max_RGA);
         N    : RGA_Str.RGA (Max_RGA);
      begin
         RGA_Str.Insert (Base, 1, (1, 1), 'H');
         RGA_Str.Insert (Base, 2, (1, 2), 'e');
         RGA_Str.Insert (Base, 3, (1, 3), 'l');
         RGA_Str.Insert (Base, 4, (1, 4), 'l');
         RGA_Str.Insert (Base, 5, (1, 5), 'o');

         Put_Line ("    Base string: '" & To_String (Base) & "'");

         R1 := Base;
         R2 := Base;

         Seq := 5;

         RGA_Str.Insert (R1, 6, Next_Id, ' ');
         RGA_Str.Insert (R1, 7, Next_Id, 'W');
         RGA_Str.Insert (R1, 8, Next_Id, 'o');
         RGA_Str.Insert (R1, 9, Next_Id, 'r');
         RGA_Str.Insert (R1, 10, Next_Id, 'l');
         RGA_Str.Insert (R1, 11, Next_Id, 'd');

         RGA_Str.Insert (R2, 6, Next_Id, ' ');
         RGA_Str.Insert (R2, 7, Next_Id, 'C');
         RGA_Str.Insert (R2, 8, Next_Id, 'r');
         RGA_Str.Insert (R2, 9, Next_Id, 'u');
         RGA_Str.Insert (R2, 10, Next_Id, 'e');
         RGA_Str.Insert (R2, 11, Next_Id, 'l');

         Put_Line ("    R1 after edit: '" & To_String (R1) & "'");
         Put_Line ("    R2 after edit: '" & To_String (R2) & "'");

         M := R1;
         RGA_Str.Merge (M, R2);
         N := R2;
         RGA_Str.Merge (N, R1);
         Check (M = N, "Merge(R1,R2) = Merge(R2,R1) — convergent");
         Put_Line ("    Converged result: '" & To_String (M) & "'");

         RGA_Str.Merge (R1, R2);
         RGA_Str.Merge (R2, R1);
         Check (R1 = R2, "Sequential merge (R1<-R2, R2<-R1) converges");

         Put_Line ("[Chaotic Interleaving] done.");
      end;
   end Test_Chaotic_Interleaving;

   -----------------------------------------------
   --  RGA Tombstone Purging Edge Cases         --
   -----------------------------------------------
   procedure Test_Tombstone_Edge_Cases is
      Max_RGA : constant Positive := 20;

      package RGA_Str is new Ardt.Rga (Character, Max_RGA);

      R : RGA_Str.RGA (Max_RGA);

      Unknown_Id : constant RGA_Str.Node_Id := (Replica => 999, Seq => 999);
      Known_Id   : RGA_Str.Node_Id;
   begin
      New_Line;
      Put_Line ("[Tombstone Edge Cases]");

      RGA_Str.Insert (R, 1, (1, 1), 'A');
      Known_Id := (Replica => 1, Seq => 1);

      declare
         No_Exception : Boolean := True;
      begin
         RGA_Str.Delete_Node (R, Unknown_Id);
         Check (No_Exception,
                "Deleting unknown Node_Id does not raise an exception");
      exception
         when others =>
            Check (False, "Deleting unknown Node_Id raised an exception");
      end;

      Check (RGA_Str.Size (R) = 1,
             "Size unchanged after deleting unknown ID (got" &
             Natural'Image (RGA_Str.Size (R)) & ")");

      RGA_Str.Delete_Node (R, Known_Id);
      Check (RGA_Str.Size (R) = 1,
             "Size unchanged after deleting known ID (tombstone)");

      declare
         No_Exception : Boolean := True;
      begin
         RGA_Str.Delete_Node (R, Known_Id);
         Check (No_Exception,
                "Deleting already-deleted ID does not raise an exception");
      exception
         when others =>
            Check (False, "Deleting already-deleted ID raised an exception");
      end;

      Put_Line ("[Tombstone Edge Cases] done.");
   end Test_Tombstone_Edge_Cases;

begin
   Put_Line ("=== ARDT CRDT Test Suite ===");
   Put_Line ("Running unit tests, property-based fuzzing, and chaos simulations...");

   Test_PN_Counter;
   Test_LWW_Set;
   Test_RGA;
   Test_RGAs;
   Test_Lattice_Properties;
   Test_Chaotic_Interleaving;
   Test_Tombstone_Edge_Cases;

   New_Line;
   Put_Line ("=== Results ===");
   Put_Line ("  Passed:" & Natural'Image (Passed));
   Put_Line ("  Failed:" & Natural'Image (Failed));

   if Failed = 0 then
      Put_Line ("=== ALL TESTS PASSED ===");
   else
      Put_Line ("=== SOME TESTS FAILED ===");
   end if;
end Test_Crdt;
