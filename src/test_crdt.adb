with Ada.Text_IO;
with Ada.Numerics.Discrete_Random;
with Ada.Numerics.Float_Random;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with CRDT.Core;
with CRDT.Pn_Counters;
with CRDT.Lww_Element_Sets;
with CRDT.Rga;
with CRDT.Rgas;
with CRDT.Sync;
with CRDT.Sync.State_Based;
with CRDT.Sync.Op_Based;
with CRDT.Sequences.Yjs;
with CRDT.Sequences.Naive;

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
      Max_A : constant Positive := 5;
      C     : CRDT.Pn_Counters.PN_Counter (Max_A);
      V     : Integer;
   begin
      New_Line;
      Put_Line ("[PN-Counter]");

      V := CRDT.Pn_Counters.Value (C);
      Check (V = 0, "Initial value = 0 (got" & Integer'Image (V) & ")");

      CRDT.Pn_Counters.Increment (C, 5, 1);
      V := CRDT.Pn_Counters.Value (C);
      Check (V = 5, "After Increment (C, 5, Actor=>1): value = 5 (got" & Integer'Image (V) & ")");

      CRDT.Pn_Counters.Decrement (C, 3, 1);
      V := CRDT.Pn_Counters.Value (C);
      Check (V = 2, "After Decrement (C, 3, Actor=>1): value = 2 (got" & Integer'Image (V) & ")");

      CRDT.Pn_Counters.Increment (C, 1, 1);
      V := CRDT.Pn_Counters.Value (C);
      Check (V = 3, "After Increment (C, 1, Actor=>1): value = 3 (got" & Integer'Image (V) & ")");

      CRDT.Pn_Counters.Decrement (C, 4, 1);
      V := CRDT.Pn_Counters.Value (C);
      Check (V = -1, "After Decrement (C, 4, Actor=>1): value = -1 (got" & Integer'Image (V) & ")");

      declare
         D : CRDT.Pn_Counters.PN_Counter (Max_A);
      begin
         CRDT.Pn_Counters.Increment (D, 10, 2);
         CRDT.Pn_Counters.Merge (C, D);
         V := CRDT.Pn_Counters.Value (C);
         Check (V = 9, "After Merge with D (Actor2 P=10): value = P(5+10) - N(6) = 9 (got" & Integer'Image (V) & ")");
      end;

      Put_Line ("[PN-Counter] done.");
   end Test_PN_Counter;

   -----------------------------
   --  LWW-Element-Set Tests  --
   -----------------------------
   procedure Test_LWW_Set is
      Max_Size : constant Positive := 10;

      package LWW is new CRDT.Lww_Element_Sets (Integer, Max_Size);

      S : LWW.LWW_Element_Set (Max_Size);

      function Lamport (S : Natural; N : CRDT.Core.Replica_Id)
                        return CRDT.Core.Lamport_Time is
        (Stamp => S, Node => N);
   begin
      New_Line;
      Put_Line ("[LWW-Element-Set]");

      Check (not LWW.Contains (S, 42), "Empty set: Contains (42) = False");

      LWW.Add (S, 42, Lamport (100, 1));
      Check (LWW.Contains (S, 42), "Add (42, ts=100/1): Contains (42) = True");

      LWW.Add (S, 7, Lamport (200, 1));
      Check (LWW.Contains (S, 7), "Add (7, ts=200/1): Contains (7) = True");

      LWW.Remove (S, 42, Lamport (150, 1));
      Check (not LWW.Contains (S, 42),
             "Remove (42, ts=150/1): Contains (42) = False (150 > 100)");

      LWW.Add (S, 42, Lamport (200, 1));
      Check (LWW.Contains (S, 42),
             "Re-add (42, ts=200/1): Contains (42) = True (200 > 150)");

      LWW.Remove (S, 42, Lamport (250, 1));
      Check (not LWW.Contains (S, 42),
             "Remove (42, ts=250/1): Contains (42) = False (250 > 200)");

      LWW.Remove (S, 7, Lamport (300, 2));
      Check (not LWW.Contains (S, 7),
             "Remove (7, ts=300/2): Contains (7) = False");

      LWW.Add (S, 7, Lamport (350, 1));
      Check (LWW.Contains (S, 7),
             "Re-add (7, ts=350/1): Contains (7) = True (350 > 300)");

      -- Ordered by Stamp first, then Node for tie-breaking:
      -- Remove(7, 300/2) vs Add(7, 350/1): 350 > 300, so present.
      -- If stamps were equal, node 1 would win over node 2.

      declare
         T : LWW.LWW_Element_Set (Max_Size);
      begin
         LWW.Add (T, 99, Lamport (500, 3));
         LWW.Merge (S, T);
         Check (LWW.Contains (S, 99),
                "Merge with set containing (99, ts=500/3): Contains (99) = True");
      end;

      Put_Line ("[LWW-Element-Set] done.");
   end Test_LWW_Set;

   -----------------------
   --  RGA Tests        --
   -----------------------
   procedure Test_RGA is
      Max_Sz  : constant Positive := 10;
      Seq     : Natural := 0;

      package RGA_Str is new CRDT.Rga (Character, Max_Sz);

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

      package RGAs_Pkg is new CRDT.Rgas (Character, Max_Sz, Max_Cnt);

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
         Max_PN : constant Positive := 10;
         A : CRDT.Pn_Counters.PN_Counter (Max_PN);
         B : CRDT.Pn_Counters.PN_Counter (Max_PN);
         C : CRDT.Pn_Counters.PN_Counter (Max_PN);
         D : CRDT.Pn_Counters.PN_Counter (Max_PN);
         E : CRDT.Pn_Counters.PN_Counter (Max_PN);
         Op : Natural;
      begin
         for I in 1 .. Num_Ops loop
            Op := Pos_Random.Random (Pos_Gen) mod 2;
            if Op = 0 then
               CRDT.Pn_Counters.Increment (A, Nat_Random.Random (Nat_Gen) mod 20 + 1, 1);
            else
               CRDT.Pn_Counters.Decrement (A, Nat_Random.Random (Nat_Gen) mod 20 + 1, 1);
            end if;
         end loop;

         Pos_Random.Reset (Pos_Gen, Seed2);
         Nat_Random.Reset (Nat_Gen, Seed2);
         for I in 1 .. Num_Ops loop
            Op := Pos_Random.Random (Pos_Gen) mod 2;
            if Op = 0 then
               CRDT.Pn_Counters.Increment (B, Nat_Random.Random (Nat_Gen) mod 20 + 1, 2);
            else
               CRDT.Pn_Counters.Decrement (B, Nat_Random.Random (Nat_Gen) mod 20 + 1, 2);
            end if;
         end loop;

         Pos_Random.Reset (Pos_Gen, Seed3);
         Nat_Random.Reset (Nat_Gen, Seed3);
         for I in 1 .. Num_Ops loop
            Op := Pos_Random.Random (Pos_Gen) mod 2;
            if Op = 0 then
               CRDT.Pn_Counters.Increment (C, Nat_Random.Random (Nat_Gen) mod 20 + 1, 3);
            else
               CRDT.Pn_Counters.Decrement (C, Nat_Random.Random (Nat_Gen) mod 20 + 1, 3);
            end if;
         end loop;

         D := A;
         CRDT.Pn_Counters.Merge (D, B);
         E := B;
         CRDT.Pn_Counters.Merge (E, A);
         Check (CRDT.Pn_Counters.Value (D) = CRDT.Pn_Counters.Value (E),
                "PN-Counter commutativity: Merge(A,B) = Merge(B,A)");

         D := A;
         CRDT.Pn_Counters.Merge (D, A);
         Check (CRDT.Pn_Counters.Value (D) = CRDT.Pn_Counters.Value (A),
                "PN-Counter idempotency: Merge(A,A) = A");

         D := A;
         CRDT.Pn_Counters.Merge (D, B);
         CRDT.Pn_Counters.Merge (D, C);
         E := A;
         declare
            Tmp : CRDT.Pn_Counters.PN_Counter (Max_PN) := B;
         begin
            CRDT.Pn_Counters.Merge (Tmp, C);
            CRDT.Pn_Counters.Merge (E, Tmp);
         end;
         Check (CRDT.Pn_Counters.Value (D) = CRDT.Pn_Counters.Value (E),
                "PN-Counter associativity: Merge(Merge(A,B),C) = Merge(A,Merge(B,C))");
      end;

      --------------------------
      --  LWW-Element-Set     --
      --------------------------
      declare
         Max_LWW : constant Positive := 500;

         package LWW is new CRDT.Lww_Element_Sets (Integer, Max_LWW);

         use type LWW.LWW_Element_Set;

         A : LWW.LWW_Element_Set (Max_LWW);
         B : LWW.LWW_Element_Set (Max_LWW);
         C : LWW.LWW_Element_Set (Max_LWW);
         D : LWW.LWW_Element_Set (Max_LWW);
         E : LWW.LWW_Element_Set (Max_LWW);
         Op : Natural;
         El : Integer;
      begin
         for I in 1 .. 50 loop
            LWW.Add (A, I, (Stamp => I * 100, Node => 1));
            LWW.Add (B, I, (Stamp => I * 100 + 50, Node => 2));
            LWW.Add (C, I, (Stamp => I * 100 + 25, Node => 3));
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

         package RGA_Ch is new CRDT.Rga (Character, Max_RGA);

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

      package RGA_Str is new CRDT.Rga (Character, Max_RGA);

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
         Check (M = N, "Merge(R1,R2) = Merge(R2,R1) - convergent");
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

      package RGA_Str is new CRDT.Rga (Character, Max_RGA);

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

   -----------------------------------------------
   --  Structural Splitting (Yjs-style)         --
   -----------------------------------------------
   procedure Test_Structural_Splitting is
      Max_RGA : constant Positive := 20;
      package RGA_Str is new CRDT.Rga (Character, Max_RGA, Max_Stride => 10);
      R : RGA_Str.RGA (Max_RGA);
      Seq : Natural := 0;
   begin
      New_Line;
      Put_Line ("[Structural Splitting]");

      -- Insert a bulk of 5 characters
      RGA_Str.Insert_Bulk (R, 1, (1, 1), "Hello");
      Check (RGA_Str.Size (R) = 5, "After Insert_Bulk ""Hello"" at 1: size = 5");
      Check (RGA_Str.Get (R, 1) = 'H', "Get (1) = 'H'");
      Check (RGA_Str.Get (R, 3) = 'l', "Get (3) = 'l'");
      Check (RGA_Str.Get (R, 5) = 'o', "Get (5) = 'o'");
      Check (RGA_Str.Count (R) = 1, "1 item after bulk insert");

      -- Insert a character in the middle of the bulk (between 'l' and 'l' at pos 3)
      RGA_Str.Insert (R, 3, (1, 2), 'X');
      Check (RGA_Str.Size (R) = 6, "After split insert: size = 6");
      Check (RGA_Str.Get (R, 1) = 'H', "Split: Get (1) = 'H'");
      Check (RGA_Str.Get (R, 2) = 'e', "Split: Get (2) = 'e'");
      Check (RGA_Str.Get (R, 3) = 'X', "Split: Get (3) = 'X'");
      Check (RGA_Str.Get (R, 4) = 'l', "Split: Get (4) = 'l'");
      Check (RGA_Str.Get (R, 5) = 'l', "Split: Get (5) = 'l'");
      Check (RGA_Str.Get (R, 6) = 'o', "Split: Get (6) = 'o'");

      Check (RGA_Str.Count (R) >= 3, "At least 3 items after split");

      Put_Line ("[Structural Splitting] done.");
   end Test_Structural_Splitting;

   -----------------------------------------------
   --  State Vector / Delta Sync                --
   -----------------------------------------------
   procedure Test_Delta_Sync is
      Max_RGA : constant Positive := 20;
      package RGA_Str is new CRDT.Rga (Character, Max_RGA);
      A : RGA_Str.RGA (Max_RGA);
      B : RGA_Str.RGA (Max_RGA);
      SV : RGA_Str.Replica_Max_Seq_Array (1 .. 10);
      SV_Cnt : Natural;
   begin
      New_Line;
      Put_Line ("[Delta Sync]");

      RGA_Str.Insert (A, 1, (1, 1), 'A');
      RGA_Str.Insert (A, 2, (1, 2), 'B');
      RGA_Str.Insert (A, 3, (1, 3), 'C');

      RGA_Str.Insert (B, 1, (2, 1), 'X');

      RGA_Str.Compute_State_Vector (B, SV, SV_Cnt);
      Check (SV_Cnt >= 1, "State vector has at least 1 entry");
      Check (SV_Cnt <= 10, "State vector within bounds");

      RGA_Str.Sync_Delta (B, A, SV, SV_Cnt);
      Check (RGA_Str.Size (B) >= 4,
             "After delta sync B size >= 4 (got" &
             Natural'Image (RGA_Str.Size (B)) & ")");
      Check (RGA_Str.Get (B, 1) = 'A', "Delta: Get (1) = 'A'");
      Check (RGA_Str.Get (B, 2) = 'X', "Delta: Get (2) = 'X'");
      Check (RGA_Str.Get (B, 3) = 'B', "Delta: Get (3) = 'B'");
      Check (RGA_Str.Get (B, 4) = 'C', "Delta: Get (4) = 'C'");

      Put_Line ("[Delta Sync] done.");
   end Test_Delta_Sync;

   -----------------------------------------------
   --  Tombstone Garbage Collection             --
   -----------------------------------------------
   procedure Test_Tombstone_GC is
      Max_RGA : constant Positive := 20;
      package RGA_Str is new CRDT.Rga (Character, Max_RGA);
      R : RGA_Str.RGA (Max_RGA);
   begin
      New_Line;
      Put_Line ("[Tombstone GC]");

      RGA_Str.Insert (R, 1, (1, 1), 'A');
      RGA_Str.Insert (R, 2, (1, 2), 'B');
      RGA_Str.Insert (R, 3, (1, 3), 'C');

      Check (RGA_Str.Size (R) = 3, "Before delete: size = 3");
      Check (RGA_Str.Count (R) = 3, "Before delete: item count = 3");

      RGA_Str.Delete (R, 2);
      Check (RGA_Str.Size (R) = 3, "After delete: size = 3 (tombstone still counts)");

      RGA_Str.Compact (R);
      Check (RGA_Str.Size (R) = 2, "After compact: size = 2");
      Check (RGA_Str.Get (R, 1) = 'A', "Compact: Get (1) = 'A'");
      Check (RGA_Str.Get (R, 2) = 'C', "Compact: Get (2) = 'C'");

      Put_Line ("[Tombstone GC] done.");
   end Test_Tombstone_GC;

   -----------------------------------------------
   --  Stream Serialization                     --
   -----------------------------------------------
   procedure Test_Serialization is
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

      Check (RGA_Str.Size (Dst) = 6,
             "Deserialized size = 6 (got" &
             Natural'Image (RGA_Str.Size (Dst)) & ")");
      Check (RGA_Str.Get (Dst, 1) = 'H', "Deserialized Get (1) = 'H'");
      Check (RGA_Str.Get (Dst, 4) = 'A', "Deserialized Get (4) = 'A'");
      Check (RGA_Str.Get (Dst, 6) = 'a', "Deserialized Get (6) = 'a'");

      -- Verify equality of round-trip
      declare
         use type RGA_Str.RGA;
      begin
         Check (Src = Dst, "Round-trip serialization: Src = Dst");
      end;

      Put_Line ("[Serialization] done.");
   end Test_Serialization;

   -----------------------------------------------
   --  Iterator Tests (Yjs Engine)              --
   -----------------------------------------------
   procedure Test_Iterators is
      Max_RGA : constant Positive := 20;
      Seq     : Natural := 0;

      package RGA_Str is new CRDT.Sequences.Yjs (Character, Max_RGA);

      R : RGA_Str.RGA (Max_RGA);

      function Next_Id return RGA_Str.Node_Id is
      begin
         Seq := Seq + 1;
         return (Replica => 1, Seq => Seq);
      end Next_Id;

   begin
      New_Line;
      Put_Line ("[Iterators]");

      RGA_Str.Insert (R, 1, Next_Id, 'A');
      RGA_Str.Insert (R, 2, Next_Id, 'B');
      RGA_Str.Insert (R, 3, Next_Id, 'C');
      Check (RGA_Str.Size (R) = 3, "Iterator prep: size = 3");

      -- Test cursor-based iteration
      declare
         Pos  : RGA_Str.Cursor := RGA_Str.First (R);
         C    : Character;
         Cnt  : Natural := 0;
      begin
         while RGA_Str.Has_Element (Pos) loop
            C := RGA_Str.Element (R, Pos);
            Cnt := Cnt + 1;
            if Cnt = 1 then
               Check (C = 'A', "Iterator element 1 = 'A'");
            elsif Cnt = 2 then
               Check (C = 'B', "Iterator element 2 = 'B'");
            elsif Cnt = 3 then
               Check (C = 'C', "Iterator element 3 = 'C'");
            end if;
            exit when Cnt >= 3;
            RGA_Str.Next (R, Pos);
         end loop;
         Check (Cnt = 3, "Iterator traversed all 3 elements");
      end;

      Put_Line ("[Iterators] done.");
   end Test_Iterators;

   -----------------------------------------------
   --  Naive Engine Tests                      --
   -----------------------------------------------
   procedure Test_Naive_Engine is
      Max_RGA : constant Positive := 20;
      Seq     : Natural := 0;

      package RGA_Str is new CRDT.Sequences.Naive (Character, Max_RGA);

      R : RGA_Str.RGA (Max_RGA);

      function Next_Id return RGA_Str.Node_Id is
      begin
         Seq := Seq + 1;
         return (Replica => 1, Seq => Seq);
      end Next_Id;

   begin
      New_Line;
      Put_Line ("[Naive Engine]");

      Check (RGA_Str.Size (R) = 0, "Naive initial size = 0");

      RGA_Str.Insert (R, 1, Next_Id, 'a');
      Check (RGA_Str.Size (R) = 1, "Naive Insert 'a': size = 1");
      Check (RGA_Str.Get (R, 1) = 'a', "Naive Get (1) = 'a'");

      RGA_Str.Insert (R, 2, Next_Id, 'b');
      RGA_Str.Insert (R, 3, Next_Id, 'c');
      Check (RGA_Str.Size (R) = 3, "Naive Insert 'b','c': size = 3");
      Check (RGA_Str.Get (R, 1) = 'a', "Naive Get (1) = 'a'");
      Check (RGA_Str.Get (R, 2) = 'b', "Naive Get (2) = 'b'");
      Check (RGA_Str.Get (R, 3) = 'c', "Naive Get (3) = 'c'");

      RGA_Str.Delete (R, 2);
      Check (RGA_Str.Size (R) = 3, "Naive Delete (2): size still 3 (tombstone)");

      -- Test cursor iteration
      declare
         Pos  : RGA_Str.Cursor := RGA_Str.First (R);
         C    : Character;
         Cnt  : Natural := 0;
      begin
         while RGA_Str.Has_Element (Pos) loop
            C := RGA_Str.Element (R, Pos);
            Cnt := Cnt + 1;
            if Cnt = 1 then
               Check (C = 'a', "Naive iterator element 1 = 'a'");
            elsif Cnt = 2 then
               Check (C = 'b', "Naive iterator element 2 = 'b'");
            elsif Cnt = 3 then
               Check (C = 'c', "Naive iterator element 3 = 'c'");
            end if;
            exit when Cnt >= 3;
            RGA_Str.Next (R, Pos);
         end loop;
         Check (Cnt = 3, "Naive iterator traversed all 3 elements");
      end;

      -- Merge test
      declare
         R2 : RGA_Str.RGA (Max_RGA);
      begin
         RGA_Str.Insert (R2, 1, (Replica => 2, Seq => 1), 'x');
         RGA_Str.Merge (R, R2);
         Check (RGA_Str.Size (R) >= 3, "Naive Merge: size >= 3");
      end;

      Put_Line ("[Naive Engine] done.");
   end Test_Naive_Engine;

   -----------------------------------------------
   --  Sync Layer Tests                        --
   -----------------------------------------------
   procedure Test_Sync_Layer is
      use type CRDT.Sync.Op_Based.Op_Kind;
   begin
      New_Line;
      Put_Line ("[Sync Layer]");

      declare
         Config : CRDT.Sync.State_Based.Sync_Config :=
           (Max_Replicas => 4, Delta_Sync => True, HLC_Node => 1);
         Local  : CRDT.Sync.State_Based.Replica_State :=
           CRDT.Sync.State_Based.Create (Config);
         Remote : CRDT.Sync.State_Based.Replica_State :=
           CRDT.Sync.State_Based.Create (Config);
      begin
         CRDT.Sync.State_Based.Merge (Local, Remote);
         Check (True, "State-based sync: merge completed without error");
      end;

      declare
         Log : CRDT.Sync.Op_Based.Op_Log (Capacity => 100);
      begin
         CRDT.Sync.Op_Based.Append (Log,
           (Kind => CRDT.Sync.Op_Based.Op_Insert, Seq => 1, Node => 1, Position => 1));
         CRDT.Sync.Op_Based.Append (Log,
           (Kind => CRDT.Sync.Op_Based.Op_Delete, Seq => 2, Node => 1, Del_Position => 1));
         Check (CRDT.Sync.Op_Based.Size (Log) = 2,
                "Op-based sync: log size = 2");

         CRDT.Sync.Op_Based.Acknowledge (Log, 1);
         Check (CRDT.Sync.Op_Based.Size (Log) = 1,
                "Op-based sync: after ack up to seq 1, size = 1");

         CRDT.Sync.Op_Based.Compact (Log);
         Check (CRDT.Sync.Op_Based.Size (Log) = 1,
                "Op-based sync: after compact, size = 1");

         declare
            Op : constant CRDT.Sync.Op_Based.Operation :=
              CRDT.Sync.Op_Based.Get (Log, 1);
         begin
            Check (Op.Kind = CRDT.Sync.Op_Based.Op_Delete,
                   "Op-based sync: Get remaining op = Delete");
         end;
      end;

      Put_Line ("[Sync Layer] done.");
   end Test_Sync_Layer;

   ---------------------------------------------------
   --  Three-Way Split Brain (Concurrent Fork)      --
   ---------------------------------------------------
   procedure Test_Three_Way_Split is
      Max_RGA : constant Positive := 50;
      Seq     : Natural := 0;

      package RGA_Str is new CRDT.Rga (Character, Max_RGA);

      function To_String (R : RGA_Str.RGA) return String is
         Buf : String (1 .. RGA_Str.Size (R));
      begin
         for I in 1 .. RGA_Str.Size (R) loop
            Buf (I) := RGA_Str.Get (R, I);
         end loop;
         return Buf;
      end To_String;

      function Next_Id (Rep : CRDT.Core.Replica_Id) return RGA_Str.Node_Id is
      begin
         Seq := Seq + 1;
         return (Replica => Rep, Seq => Seq);
      end Next_Id;

      use type RGA_Str.RGA;

      Base : RGA_Str.RGA (Max_RGA);
      R1   : RGA_Str.RGA (Max_RGA);
      R2   : RGA_Str.RGA (Max_RGA);
      R3   : RGA_Str.RGA (Max_RGA);
   begin
      New_Line;
      Put_Line ("[Three-Way Split Brain]");

      RGA_Str.Insert (Base, 1, (1, 1), 'H');
      RGA_Str.Insert (Base, 2, (1, 2), 'e');
      RGA_Str.Insert (Base, 3, (1, 3), 'l');
      RGA_Str.Insert (Base, 4, (1, 4), 'l');
      RGA_Str.Insert (Base, 5, (1, 5), 'o');

      Seq := 5;

      -- R1: insert ' ' + "World" at end
      R1 := Base;
      RGA_Str.Insert (R1, 6, Next_Id (1), ' ');
      RGA_Str.Insert (R1, 7, Next_Id (1), 'W');
      RGA_Str.Insert (R1, 8, Next_Id (1), 'o');
      RGA_Str.Insert (R1, 9, Next_Id (1), 'r');
      RGA_Str.Insert (R1, 10, Next_Id (1), 'l');
      RGA_Str.Insert (R1, 11, Next_Id (1), 'd');

      -- R2: delete position 2 ('e')
      R2 := Base;
      RGA_Str.Delete (R2, 2);

      -- R3: insert 'X' at position 2
      R3 := Base;
      RGA_Str.Insert (R3, 2, Next_Id (3), 'X');

      -- Build a unified state by merging all three
      declare
         M : RGA_Str.RGA (Max_RGA) := R1;
      begin
         RGA_Str.Merge (M, R2);
         RGA_Str.Merge (M, R3);
         Check (RGA_Str.Size (M) >= 5, "Unified state size >= 5 (got" &
                Natural'Image (RGA_Str.Size (M)) & ") — " & To_String (M));
      end;

      -- Build final merged states in different orders, verify convergence
      declare
         M12 : RGA_Str.RGA (Max_RGA) := R1;
         M21 : RGA_Str.RGA (Max_RGA) := R2;
         M13 : RGA_Str.RGA (Max_RGA) := R1;
         M31 : RGA_Str.RGA (Max_RGA) := R3;
         M23 : RGA_Str.RGA (Max_RGA) := R2;
         M32 : RGA_Str.RGA (Max_RGA) := R3;
      begin
         RGA_Str.Merge (M12, R2);  RGA_Str.Merge (M12, R3);
         RGA_Str.Merge (M21, R1);  RGA_Str.Merge (M21, R3);
         RGA_Str.Merge (M13, R3);  RGA_Str.Merge (M13, R2);
         RGA_Str.Merge (M31, R1);  RGA_Str.Merge (M31, R2);
         RGA_Str.Merge (M23, R3);  RGA_Str.Merge (M23, R1);
         RGA_Str.Merge (M32, R2);  RGA_Str.Merge (M32, R1);

         -- All merge orders produce states with same visible size
         declare
            Siz : constant Natural := RGA_Str.Size (M12);
         begin
            Check (RGA_Str.Size (M21) = Siz
                   and then RGA_Str.Size (M13) = Siz
                   and then RGA_Str.Size (M31) = Siz
                   and then RGA_Str.Size (M23) = Siz
                   and then RGA_Str.Size (M32) = Siz,
                   "All 6 merge orders have same size =" &
                   Natural'Image (Siz));
         end;

         -- Merging any permutation into M12 is idempotent (convergence)
         declare
            Tmp : RGA_Str.RGA (Max_RGA) := M12;
         begin
            RGA_Str.Merge (Tmp, M21);
            Check (RGA_Str.Size (Tmp) = RGA_Str.Size (M12),
                   "Merge(M12, M21) preserves size");
         end;
         declare
            Tmp : RGA_Str.RGA (Max_RGA) := M12;
         begin
            RGA_Str.Merge (Tmp, M31);
            Check (RGA_Str.Size (Tmp) = RGA_Str.Size (M12),
                   "Merge(M12, M31) preserves size");
         end;
      end;

      Put_Line ("[Three-Way Split Brain] done.");
   end Test_Three_Way_Split;

   ---------------------------------------------------
   --  Byte-Boundary Round-tripping                 --
   ---------------------------------------------------
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
      Check (RGA_Str.Size (Dst) = 0,
             "Empty RGA round-trip: size = 0");
      declare
         use type RGA_Str.RGA;
      begin
         Check (Src = Dst, "Empty RGA round-trip: Src = Dst");
      end;

      -- Null byte (Character'Val(0))
      RGA_Str.Insert (Src, 1, (1, 1), Character'Val (0));
      Create (F, Out_File, "/tmp/crdt_serialize_0.bin");
      RGA_Str.RGA'Write (Stream (F), Src);
      Close (F);
      Open (F, In_File, "/tmp/crdt_serialize_0.bin");
      RGA_Str.RGA'Read (Stream (F), Dst);
      Close (F);
      Check (RGA_Str.Get (Dst, 1) = Character'Val (0),
             "Null byte round-trip: Get(1) = 0");
      declare
         use type RGA_Str.RGA;
      begin
         Check (Src = Dst, "Null byte round-trip: Src = Dst");
      end;

      -- High byte (Character'Val(255))
      RGA_Str.Insert (Src, 2, (1, 2), Character'Val (255));
      Create (F, Out_File, "/tmp/crdt_serialize_255.bin");
      RGA_Str.RGA'Write (Stream (F), Src);
      Close (F);
      Open (F, In_File, "/tmp/crdt_serialize_255.bin");
      RGA_Str.RGA'Read (Stream (F), Dst);
      Close (F);
      Check (RGA_Str.Get (Dst, 1) = Character'Val (0),
             "High byte round-trip: Get(1) = 0 (unchanged)");
      Check (RGA_Str.Get (Dst, 2) = Character'Val (255),
             "High byte round-trip: Get(2) = 255");
      declare
         use type RGA_Str.RGA;
      begin
         Check (Src = Dst, "High byte round-trip: Src = Dst");
      end;

      Put_Line ("[Byte-Boundary Round-tripping] done.");
   end Test_Byte_Boundary;

   ---------------------------------------------------
   --  Out-of-Order Delta Appends                   --
   ---------------------------------------------------
   procedure Test_Out_Of_Order_Delta is
      Max_RGA : constant Positive := 20;
      package RGA_Str is new CRDT.Rga (Character, Max_RGA);
      A : RGA_Str.RGA (Max_RGA);
      B : RGA_Str.RGA (Max_RGA);
      SV : RGA_Str.Replica_Max_Seq_Array (1 .. 10);
      SV_Cnt : Natural;
   begin
      New_Line;
      Put_Line ("[Out-of-Order Delta Appends]");

      RGA_Str.Insert (A, 1, (1, 1), 'A');
      RGA_Str.Insert (A, 2, (1, 2), 'B');
      RGA_Str.Insert (A, 3, (1, 3), 'C');

      -- Fabricate a state vector claiming B has seen ops A never produced
      SV (1) := (Replica => 999, Max_Seq => 999);
      SV_Cnt := 1;

      declare
         No_Exception : Boolean := True;
      begin
         RGA_Str.Sync_Delta (B, A, SV, SV_Cnt);
         Check (No_Exception,
                "Delta with unseen replica does not raise an exception");
      exception
         when others =>
            Check (False, "Delta with unseen replica raised an exception");
      end;

      Check (RGA_Str.Size (B) = 3,
             "After ooo delta B has all 3 elements (got" &
             Natural'Image (RGA_Str.Size (B)) & ")");
      Check (RGA_Str.Get (B, 1) = 'A', "Ooo delta: Get (1) = 'A'");
      Check (RGA_Str.Get (B, 2) = 'B', "Ooo delta: Get (2) = 'B'");
      Check (RGA_Str.Get (B, 3) = 'C', "Ooo delta: Get (3) = 'C'");

      -- Now test with a real state vector that's incomplete (missing replica 1)
      -- This should still work: the missing replica means all its items are newer.
      declare
         use type RGA_Str.RGA;
         C : RGA_Str.RGA (Max_RGA);
      begin
         RGA_Str.Insert (C, 1, (2, 1), 'X');
         RGA_Str.Compute_State_Vector (C, SV, SV_Cnt);
         Check (SV_Cnt >= 1, "State vector computed");
         declare
            No_Exception : Boolean := True;
         begin
            RGA_Str.Sync_Delta (B, A, SV, SV_Cnt);
            Check (No_Exception,
                   "Delta with incomplete SV does not raise an exception");
         exception
            when others =>
               Check (False, "Delta with incomplete SV raised an exception");
         end;
         Check (RGA_Str.Size (B) = 3,
                "After incomplete SV delta B still has 3 elements (got" &
                Natural'Image (RGA_Str.Size (B)) & ")");
      end;

      Put_Line ("[Out-of-Order Delta Appends] done.");
   end Test_Out_Of_Order_Delta;

   ---------------------------------------------------
   --  Fuzzing Network Partitions (50-op dropout)   --
   ---------------------------------------------------
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

      --  Phase 1: partition — S3 is cut off for 50 ops
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
         Check (Divergent,
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
         Check (Conv_A, "S1 = S2 after async rejoin");
         Check (Conv_B, "S2 = S3 after async rejoin");
         Check (Conv_C, "S1 = S3 after async rejoin (transitive)");
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
         Check (R1 = R2, "RGA: R1 = R2 after partition sync");

         --  R3 catches up via async merge
         RGA_Str.Merge (R1, R3);
         RGA_Str.Merge (R3, R1);
         RGA_Str.Merge (R2, R3);
         RGA_Str.Merge (R3, R2);

         Check (R1 = R2, "RGA: R1 = R2 after async rejoin");
         Check (R2 = R3, "RGA: R2 = R3 after async rejoin");
         Check (R1 = R3, "RGA: R1 = R3 after async rejoin (transitive)");
      end;

      Put_Line ("[Fuzzing Network Partitions] done.");
   end Test_Fuzzing_Network_Partitions;

   -----------------------------------------------
   --  Property-Based Fuzzer (10,000 runs)      --
   -----------------------------------------------
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
             if not Assoc_Ok then
                Failed := Failed + 1;
                Put_Line ("  FAIL: Fuzz associativity at iteration" & Natural'Image (I));
             else
                Passed := Passed + 1;
             end if;
          end;

         if I mod 100 = 0 then
            Put_Line ("    fuzz iteration" & Natural'Image (I));
         end if;
      end loop;

      Put_Line ("[Property Fuzzer] done.");
   end Test_Property_Fuzzer;

   -----------------------------------------------
   --  Anti-Interleaving (Concurrent Insert)    --
   -----------------------------------------------
   procedure Test_Anti_Interleaving is
      Max_RGA : constant Positive := 50;

      package RGA_Str is new CRDT.Rga (Character, Max_RGA);

      function To_String (R : RGA_Str.RGA) return String is
         Buf : String (1 .. RGA_Str.Size (R));
      begin
         for I in 1 .. RGA_Str.Size (R) loop
            Buf (I) := RGA_Str.Get (R, I);
         end loop;
         return Buf;
      end To_String;

      function Has_Substr (S, Sub : String) return Boolean is
      begin
         for I in S'First .. S'Last - Sub'Length + 1 loop
            if S (I .. I + Sub'Length - 1) = Sub then
               return True;
            end if;
         end loop;
         return False;
      end Has_Substr;

      use type RGA_Str.RGA;

      Base : RGA_Str.RGA (Max_RGA);
   begin
      New_Line;
      Put_Line ("[Anti-Interleaving]");

      --  Build "Hello " (6 characters, Replica 1, Seq 1..6)
      RGA_Str.Insert (Base, 1, (1, 1), 'H');
      RGA_Str.Insert (Base, 2, (1, 2), 'e');
      RGA_Str.Insert (Base, 3, (1, 3), 'l');
      RGA_Str.Insert (Base, 4, (1, 4), 'l');
      RGA_Str.Insert (Base, 5, (1, 5), 'o');
      RGA_Str.Insert (Base, 6, (1, 6), ' ');

      --  Node A (Replica 2) concurrently inserts "123" at position 7
      declare
         A : RGA_Str.RGA (Max_RGA) := Base;
      begin
         RGA_Str.Insert (A, 7, (2, 1), '1');
         RGA_Str.Insert (A, 8, (2, 2), '2');
         RGA_Str.Insert (A, 9, (2, 3), '3');

         --  Node B (Replica 3) concurrently inserts "ABC" at position 7
         declare
            B : RGA_Str.RGA (Max_RGA) := Base;
         begin
            RGA_Str.Insert (B, 7, (3, 1), 'A');
            RGA_Str.Insert (B, 8, (3, 2), 'B');
            RGA_Str.Insert (B, 9, (3, 3), 'C');

            --  Merge both ways — check semantic properties
            declare
               M1 : RGA_Str.RGA (Max_RGA) := A;
               M2 : RGA_Str.RGA (Max_RGA) := B;
            begin
               RGA_Str.Merge (M1, B);
               RGA_Str.Merge (M2, A);

               declare
                  S1 : constant String := To_String (M1);
                  S2 : constant String := To_String (M2);
               begin
                  --  Both results must have all 12 characters (6 base + 3 A + 3 B)
                  Check (RGA_Str.Size (M1) >= 12,
                         "Anti-interleaving: M1 size >= 12 (got" & Natural'Image (RGA_Str.Size (M1)) & ")");
                  Check (RGA_Str.Size (M2) >= 12,
                         "Anti-interleaving: M2 size >= 12 (got" & Natural'Image (RGA_Str.Size (M2)) & ")");

                  --  Base characters all present
                  Check (Has_Substr (S1, "H") and Has_Substr (S1, "e")
                         and Has_Substr (S1, "l") and Has_Substr (S1, "o")
                         and Has_Substr (S1, " "),
                         "Anti-interleaving: M1 has all base chars (got """ & S1 & """)");
                  Check (Has_Substr (S2, "H") and Has_Substr (S2, "e")
                         and Has_Substr (S2, "l") and Has_Substr (S2, "o")
                         and Has_Substr (S2, " "),
                         "Anti-interleaving: M2 has all base chars (got """ & S2 & """)");

                  --  All 6 concurrent chars present across both merged results
                  Check (Has_Substr (S1, "1") and Has_Substr (S1, "2") and Has_Substr (S1, "3")
                         and Has_Substr (S1, "A") and Has_Substr (S1, "B") and Has_Substr (S1, "C"),
                         "Anti-interleaving: M1 has all 6 inserted chars (got """ & S1 & """)");
                  Check (Has_Substr (S2, "1") and Has_Substr (S2, "2") and Has_Substr (S2, "3")
                         and Has_Substr (S2, "A") and Has_Substr (S2, "B") and Has_Substr (S2, "C"),
                         "Anti-interleaving: M2 has all 6 inserted chars (got """ & S2 & """)");
               end;
            end;
         end;
      end;

      Put_Line ("[Anti-Interleaving] done.");
   end Test_Anti_Interleaving;

   -----------------------------------------------
   --  HLC Clock Skew Injection                 --
   -----------------------------------------------
   procedure Test_HLC_Clock_Skew is
      Max_LWW : constant Positive := 200;

      package LWW is new CRDT.Lww_Element_Sets (Integer, Max_LWW);

      use type LWW.LWW_Element_Set;

      A : LWW.LWW_Element_Set (Max_LWW);
      B : LWW.LWW_Element_Set (Max_LWW);
      C : LWW.LWW_Element_Set (Max_LWW);
   begin
      New_Line;
      Put_Line ("[HLC Clock Skew]");

      --  Initialize all three with elements 1..10
      for I in 1 .. 10 loop
         LWW.Add (A, I, (Stamp => I * 100, Node => 1));
         LWW.Add (B, I, (Stamp => I * 100, Node => 1));
         LWW.Add (C, I, (Stamp => I * 100, Node => 1));
      end loop;

      --  Advance B's clock into the future
      for I in 1 .. 10 loop
         LWW.Add (B, 10 + I, (Stamp => 1000000 + I, Node => 2));
      end loop;

      --  Merge B into A
      LWW.Merge (A, B);

      --  A does a local add with a very small stamp (different element)
      LWW.Add (A, 999, (Stamp => 1, Node => 1));
      Check (LWW.Contains (A, 999),
             "Clock skew: local add of element 999 with Stamp=1 is present");

      --  Verify A's low-stamp add did not overwrite B's high-stamp entries
      declare
         B_Intact : Boolean := True;
      begin
         for I in 1 .. 10 loop
            if not LWW.Contains (A, 10 + I) then
               B_Intact := False;
               exit;
            end if;
         end loop;
         Check (B_Intact, "Clock skew: B's high-stamp entries survived merge");
      end;

      --  Semantic convergence: C merges from A and B in both orders
      declare
         C1 : LWW.LWW_Element_Set (Max_LWW) := C;
         C2 : LWW.LWW_Element_Set (Max_LWW) := C;
      begin
         LWW.Merge (C1, A);
         LWW.Merge (C1, B);

         LWW.Merge (C2, B);
         LWW.Merge (C2, A);

         Check (C1 = C2, "Clock skew: merge of A and B in any order converges");

         declare
            All_Converge : Boolean := True;
         begin
            for I in 1 .. 30 loop
               if LWW.Contains (A, I) /= LWW.Contains (C1, I) then
                  All_Converge := False;
                  exit;
               end if;
            end loop;
            if LWW.Contains (A, 999) /= LWW.Contains (C1, 999) then
               All_Converge := False;
            end if;
            Check (All_Converge, "Clock skew: A and C1 semantically convergent");
         end;
      end;

      Put_Line ("[HLC Clock Skew] done.");
   end Test_HLC_Clock_Skew;

   -----------------------------------------------
   --  Tombstone Saturation (Capacity Overflow) --
   -----------------------------------------------
   procedure Test_Tombstone_Saturation is
      Max_Items : constant Positive := 100;

      package RGA_Ch is new CRDT.Rga (Character, Max_Items, Max_Stride => 64);

      R : RGA_Ch.RGA (Max_Items);
   begin
      New_Line;
      Put_Line ("[Tombstone Saturation]");

      declare
         No_Exception : Boolean := True;
      begin
         --  Insert 90 elements
         for I in 1 .. 90 loop
            RGA_Ch.Insert (R, RGA_Ch.Size (R) + 1, (1, I),
                           Character'Val ((I - 1) mod 26 + 65));
         end loop;

         --  Delete 80 of them
         for I in 1 .. 80 loop
            RGA_Ch.Delete (R, 1);
         end loop;

         Check (No_Exception, "Tombstone saturation: no exception during fill/delete");
      exception
         when others =>
            Check (False, "Tombstone saturation: exception raised during fill/delete");
      end;

      Check (RGA_Ch.Count (R) >= 80, "Tombstone saturation: Count >= 80 (got" &
             Natural'Image (RGA_Ch.Count (R)) & ")");
      Check (RGA_Ch.Size (R) >= 10, "Tombstone saturation: Size >= 10 (got" &
             Natural'Image (RGA_Ch.Size (R)) & ")");

      --  Compact
      RGA_Ch.Compact (R);

      Check (RGA_Ch.Size (R) >= 10, "Tombstone saturation: after compact Size >= 10 (got" &
             Natural'Image (RGA_Ch.Size (R)) & ")");
      Check (RGA_Ch.Count (R) >= 10, "Tombstone saturation: after compact Count >= 10 (got" &
             Natural'Image (RGA_Ch.Count (R)) & ")");

      --  Insert 30 more elements
      for I in 91 .. 120 loop
         RGA_Ch.Insert (R, RGA_Ch.Size (R) + 1, (1, I),
                        Character'Val ((I - 1) mod 26 + 65));
      end loop;

      --  Verify no exception and all visible elements accessible
      declare
         No_Exception : Boolean := True;
      begin
         for I in 1 .. RGA_Ch.Size (R) loop
            declare
               Unused : constant Character := RGA_Ch.Get (R, I);
            begin
               null;
            end;
         end loop;
         Check (No_Exception, "Tombstone saturation: no exception during readback");
      exception
         when others =>
            Check (False, "Tombstone saturation: exception raised during readback");
      end;

      Check (RGA_Ch.Size (R) >= 40, "Tombstone saturation: final Size >= 40 (got" &
             Natural'Image (RGA_Ch.Size (R)) & ")");

      Put_Line ("[Tombstone Saturation] done.");
   end Test_Tombstone_Saturation;

begin
   Put_Line ("=== CRDT Test Suite ===");
   Put_Line ("Running unit tests, property-based fuzzing, and chaos simulations...");

   Test_PN_Counter;
   Test_LWW_Set;
   Test_RGA;
   Test_RGAs;
   Test_Lattice_Properties;
   Test_Chaotic_Interleaving;
   Test_Tombstone_Edge_Cases;
   Test_Structural_Splitting;
   Test_Delta_Sync;
   Test_Tombstone_GC;
   Test_Serialization;
   Test_Iterators;
   Test_Naive_Engine;
   Test_Sync_Layer;
   Test_Three_Way_Split;
   Test_Byte_Boundary;
   Test_Out_Of_Order_Delta;
   Test_Property_Fuzzer;
   Test_Anti_Interleaving;
   Test_HLC_Clock_Skew;
   Test_Tombstone_Saturation;
   Test_Fuzzing_Network_Partitions;

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
