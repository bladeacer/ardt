with CRDT.Test_Support; use CRDT.Test_Support;
with CRDT.Core;
with CRDT.Pn_Counters;
with CRDT.Lww_Element_Sets;
with CRDT.Rga;
with CRDT.Rgas;
with Ada.Text_IO; use Ada.Text_IO;

package body Test_Basic is

   procedure Run (RunR : in out Runner) is

   -----------------------
   --  PN-Counter Tests --
   -----------------------
   --  @summary PN-Counter: increment, decrement, merge, and value queries
   procedure Test_PN_Counter is
      Max_A : constant Positive := 5;
      C     : CRDT.Pn_Counters.PN_Counter (Max_A);
      V     : Integer;
   begin
      New_Line;
      Put_Line ("[PN-Counter]");

      V := CRDT.Pn_Counters.Value (C);
      RunR.Check(V = 0, "Initial value = 0 (got" & Integer'Image (V) & ")");

      CRDT.Pn_Counters.Increment (C, 5, 1);
      V := CRDT.Pn_Counters.Value (C);
      RunR.Check(V = 5, "After Increment (C, 5, Actor=>1): value = 5 (got" & Integer'Image (V) & ")");

      CRDT.Pn_Counters.Decrement (C, 3, 1);
      V := CRDT.Pn_Counters.Value (C);
      RunR.Check(V = 2, "After Decrement (C, 3, Actor=>1): value = 2 (got" & Integer'Image (V) & ")");

      CRDT.Pn_Counters.Increment (C, 1, 1);
      V := CRDT.Pn_Counters.Value (C);
      RunR.Check(V = 3, "After Increment (C, 1, Actor=>1): value = 3 (got" & Integer'Image (V) & ")");

      CRDT.Pn_Counters.Decrement (C, 4, 1);
      V := CRDT.Pn_Counters.Value (C);
      RunR.Check(V = -1, "After Decrement (C, 4, Actor=>1): value = -1 (got" & Integer'Image (V) & ")");

      declare
         D : CRDT.Pn_Counters.PN_Counter (Max_A);
      begin
         CRDT.Pn_Counters.Increment (D, 10, 2);
         CRDT.Pn_Counters.Merge (C, D);
         V := CRDT.Pn_Counters.Value (C);
         RunR.Check(V = 9, "After Merge with D (Actor2 P=10): value = P(5+10) - N(6) = 9 (got" & Integer'Image (V) & ")");
      end;

      Put_Line ("[PN-Counter] done.");
   end Test_PN_Counter;

   -----------------------------
   --  LWW-Element-Set Tests  --
   -----------------------------
   --  @summary LWW-Element-Set: add, remove, contains, timestamp resolution, and merge
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

      RunR.Check(not LWW.Contains (S, 42), "Empty set: Contains (42) = False");

      LWW.Add (S, 42, Lamport (100, 1));
      RunR.Check(LWW.Contains (S, 42), "Add (42, ts=100/1): Contains (42) = True");

      LWW.Add (S, 7, Lamport (200, 1));
      RunR.Check(LWW.Contains (S, 7), "Add (7, ts=200/1): Contains (7) = True");

      LWW.Remove (S, 42, Lamport (150, 1));
      RunR.Check(not LWW.Contains (S, 42),
             "Remove (42, ts=150/1): Contains (42) = False (150 > 100)");

      LWW.Add (S, 42, Lamport (200, 1));
      RunR.Check(LWW.Contains (S, 42),
             "Re-add (42, ts=200/1): Contains (42) = True (200 > 150)");

      LWW.Remove (S, 42, Lamport (250, 1));
      RunR.Check(not LWW.Contains (S, 42),
             "Remove (42, ts=250/1): Contains (42) = False (250 > 200)");

      LWW.Remove (S, 7, Lamport (300, 2));
      RunR.Check(not LWW.Contains (S, 7),
             "Remove (7, ts=300/2): Contains (7) = False");

      LWW.Add (S, 7, Lamport (350, 1));
      RunR.Check(LWW.Contains (S, 7),
             "Re-add (7, ts=350/1): Contains (7) = True (350 > 300)");

      -- Ordered by Stamp first, then Node for tie-breaking:
      -- Remove(7, 300/2) vs Add(7, 350/1): 350 > 300, so present.
      -- If stamps were equal, node 1 would win over node 2.

      declare
         T : LWW.LWW_Element_Set (Max_Size);
      begin
         LWW.Add (T, 99, Lamport (500, 3));
         LWW.Merge (S, T);
         RunR.Check(LWW.Contains (S, 99),
                "Merge with set containing (99, ts=500/3): Contains (99) = True");
      end;

      Put_Line ("[LWW-Element-Set] done.");
   end Test_LWW_Set;

   -----------------------
   --  RGA Tests        --
   -----------------------
   --  @summary RGA sequence: insert, get, delete (tombstone), and merge between replicas
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

      RunR.Check(RGA_Str.Size (R) = 0, "Initial size = 0 (got" & Natural'Image (RGA_Str.Size (R)) & ")");

      RGA_Str.Insert (R, 1, Next_Seq, 'a');
      RunR.Check(RGA_Str.Size (R) = 1, "Insert 'a' at 1: size = 1");
      RunR.Check(RGA_Str.Get (R, 1) = 'a', "Get (1) = 'a'");

      RGA_Str.Insert (R, 2, Next_Seq, 'b');
      RGA_Str.Insert (R, 3, Next_Seq, 'c');
      RunR.Check(RGA_Str.Size (R) = 3, "Insert 'b','c': size = 3");
      RunR.Check(RGA_Str.Get (R, 1) = 'a', "Get (1) = 'a'");
      RunR.Check(RGA_Str.Get (R, 2) = 'b', "Get (2) = 'b'");
      RunR.Check(RGA_Str.Get (R, 3) = 'c', "Get (3) = 'c'");

      RGA_Str.Insert (R, 2, Next_Seq, 'x');
      RunR.Check(RGA_Str.Size (R) = 4, "Insert 'x' at 2: size = 4");
      RunR.Check(RGA_Str.Get (R, 1) = 'a', "Get (1) = 'a'");
      RunR.Check(RGA_Str.Get (R, 2) = 'x', "Get (2) = 'x'");
      RunR.Check(RGA_Str.Get (R, 3) = 'b', "Get (3) = 'b'");
      RunR.Check(RGA_Str.Get (R, 4) = 'c', "Get (4) = 'c'");

      RGA_Str.Delete (R, 3);
      RunR.Check(RGA_Str.Size (R) = 4, "Delete (3): size unchanged = 4 (tombstone)");

      declare
         R2 : RGA_Str.RGA (Max_Sz);
      begin
         RGA_Str.Insert (R2, 1, (Replica => 2, Seq => 1), 'y');
         RGA_Str.Merge (R, R2);
         RunR.Check(RGA_Str.Size (R) >= 4, "After merge with R2 (contains 'y'): size >= 4");
         Put_Line ("    info: merged size =" & Natural'Image (RGA_Str.Size (R)));
      end;

      Put_Line ("[RGA] done.");
   end Test_RGA;

   ------------------------
   --  RGAs Tests        --
   ------------------------
   --  @summary RGAs (array of RGA sequences): append, get, and size queries
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

      RunR.Check(RGAs_Pkg.Size (RS) = 0, "Initial size = 0");

      RGAs_Pkg.RGA_Pkg.Insert (R1, 1, (Replica => 1, Seq => 1), 'a');
      RGAs_Pkg.RGA_Pkg.Insert (R1, 2, (Replica => 1, Seq => 2), 'b');
      RGAs_Pkg.Append (RS, R1);
      RunR.Check(RGAs_Pkg.Size (RS) = 1, "After append R1 ('a','b'): size = 1");

      RGAs_Pkg.RGA_Pkg.Insert (R2, 1, (Replica => 2, Seq => 1), 'c');
      RGAs_Pkg.RGA_Pkg.Insert (R2, 2, (Replica => 2, Seq => 2), 'd');
      RGAs_Pkg.Append (RS, R2);
      RunR.Check(RGAs_Pkg.Size (RS) = 2, "After append R2 ('c','d'): size = 2");

      declare
         G1 : constant RGAs_Pkg.RGA_Entry := RGAs_Pkg.Get (RS, 1);
         G2 : constant RGAs_Pkg.RGA_Entry := RGAs_Pkg.Get (RS, 2);
      begin
         RunR.Check(RGAs_Pkg.RGA_Pkg.Size (G1) = 2, "Get (1): size = 2");
         RunR.Check(RGAs_Pkg.RGA_Pkg.Size (G2) = 2, "Get (2): size = 2");
      end;

      Put_Line ("[RGAs] done.");
   end Test_RGAs;

begin
   Test_PN_Counter;
   Test_LWW_Set;
   Test_RGA;
   Test_RGAs;
end Run;
end Test_Basic;
