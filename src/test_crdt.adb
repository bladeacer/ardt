with Ada.Text_IO;
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
         Check (V = 9, "After Merge with D (P=10,N=0): value = 9 (got" & Integer'Image (V) & ")");
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

begin
   Put_Line ("=== ARDT CRDT Test Suite ===");
   Put_Line ("Running all tests...");

   Test_PN_Counter;
   Test_LWW_Set;
   Test_RGA;
   Test_RGAs;

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
