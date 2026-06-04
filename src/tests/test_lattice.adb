with CRDT.Test_Support; use CRDT.Test_Support;
with CRDT.Core;
with CRDT.Pn_Counters;
with CRDT.Lww_Element_Sets;
with CRDT.Rga;
with Ada.Numerics.Discrete_Random;
with Ada.Text_IO; use Ada.Text_IO;

package body Test_Lattice is

   procedure Run (RunR : in out Runner) is

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
         RunR.Check(CRDT.Pn_Counters.Value (D) = CRDT.Pn_Counters.Value (E),
                "PN-Counter commutativity: Merge(A,B) = Merge(B,A)");

         D := A;
         CRDT.Pn_Counters.Merge (D, A);
         RunR.Check(CRDT.Pn_Counters.Value (D) = CRDT.Pn_Counters.Value (A),
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
         RunR.Check(CRDT.Pn_Counters.Value (D) = CRDT.Pn_Counters.Value (E),
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
            RunR.Check(Commute_Ok,
                   "LWW commutativity: Merge(A,B) = Merge(B,A) (semantic)");
         end;

         D := A;
         LWW.Merge (D, A);
         RunR.Check(D = A, "LWW idempotency: Merge(A,A) = A");

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
            RunR.Check(Assoc_Ok,
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
          RunR.Check(D = A, "RGA idempotency: Merge(A,A) = A");

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
         RunR.Check(D = E, "RGA associativity: Merge(Merge(A,B),C) = Merge(A,Merge(B,C))");
      end;

      Put_Line ("[Lattice Properties] done.");
   end Test_Lattice_Properties;

begin
   Test_Lattice_Properties;
end Run;
end Test_Lattice;
