with CRDT.Test_Support; use CRDT.Test_Support;
with CRDT.Core;
with CRDT.Rga;
with Ada.Text_IO; use Ada.Text_IO;

package body Test_RGA_Features is

   procedure Run (RunR : in out Runner) is

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
         RunR.Check(M = N, "Merge(R1,R2) = Merge(R2,R1) - convergent");
         Put_Line ("    Converged result: '" & To_String (M) & "'");

         RGA_Str.Merge (R1, R2);
         RGA_Str.Merge (R2, R1);
         RunR.Check(R1 = R2, "Sequential merge (R1<-R2, R2<-R1) converges");

         Put_Line ("[Chaotic Interleaving] done.");
      end;
   end Test_Chaotic_Interleaving;

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
         RunR.Check(No_Exception,
                "Deleting unknown Node_Id does not raise an exception");
      exception
         when others =>
            RunR.Check(False, "Deleting unknown Node_Id raised an exception");
      end;

      RunR.Check(RGA_Str.Size (R) = 1,
             "Size unchanged after deleting unknown ID (got" &
             Natural'Image (RGA_Str.Size (R)) & ")");

      RGA_Str.Delete_Node (R, Known_Id);
      RunR.Check(RGA_Str.Size (R) = 1,
             "Size unchanged after deleting known ID (tombstone)");

      declare
         No_Exception : Boolean := True;
      begin
         RGA_Str.Delete_Node (R, Known_Id);
         RunR.Check(No_Exception,
                "Deleting already-deleted ID does not raise an exception");
      exception
         when others =>
            RunR.Check(False, "Deleting already-deleted ID raised an exception");
      end;

      Put_Line ("[Tombstone Edge Cases] done.");
   end Test_Tombstone_Edge_Cases;

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
      RunR.Check(RGA_Str.Size (R) = 5, "After Insert_Bulk ""Hello"" at 1: size = 5");
      RunR.Check(RGA_Str.Get (R, 1) = 'H', "Get (1) = 'H'");
      RunR.Check(RGA_Str.Get (R, 3) = 'l', "Get (3) = 'l'");
      RunR.Check(RGA_Str.Get (R, 5) = 'o', "Get (5) = 'o'");
      RunR.Check(RGA_Str.Count (R) = 1, "1 item after bulk insert");

      -- Insert a character in the middle of the bulk (between 'l' and 'l' at pos 3)
      RGA_Str.Insert (R, 3, (1, 2), 'X');
      RunR.Check(RGA_Str.Size (R) = 6, "After split insert: size = 6");
      RunR.Check(RGA_Str.Get (R, 1) = 'H', "Split: Get (1) = 'H'");
      RunR.Check(RGA_Str.Get (R, 2) = 'e', "Split: Get (2) = 'e'");
      RunR.Check(RGA_Str.Get (R, 3) = 'X', "Split: Get (3) = 'X'");
      RunR.Check(RGA_Str.Get (R, 4) = 'l', "Split: Get (4) = 'l'");
      RunR.Check(RGA_Str.Get (R, 5) = 'l', "Split: Get (5) = 'l'");
      RunR.Check(RGA_Str.Get (R, 6) = 'o', "Split: Get (6) = 'o'");

      RunR.Check(RGA_Str.Count (R) >= 3, "At least 3 items after split");

      Put_Line ("[Structural Splitting] done.");
   end Test_Structural_Splitting;

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
      RunR.Check(SV_Cnt >= 1, "State vector has at least 1 entry");
      RunR.Check(SV_Cnt <= 10, "State vector within bounds");

      RGA_Str.Sync_Delta (B, A, SV, SV_Cnt);
      RunR.Check(RGA_Str.Size (B) >= 4,
             "After delta sync B size >= 4 (got" &
             Natural'Image (RGA_Str.Size (B)) & ")");
      RunR.Check(RGA_Str.Get (B, 1) = 'A', "Delta: Get (1) = 'A'");
      RunR.Check(RGA_Str.Get (B, 2) = 'X', "Delta: Get (2) = 'X'");
      RunR.Check(RGA_Str.Get (B, 3) = 'B', "Delta: Get (3) = 'B'");
      RunR.Check(RGA_Str.Get (B, 4) = 'C', "Delta: Get (4) = 'C'");

      Put_Line ("[Delta Sync] done.");
   end Test_Delta_Sync;

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

      RunR.Check(RGA_Str.Size (R) = 3, "Before delete: size = 3");
      RunR.Check(RGA_Str.Count (R) = 3, "Before delete: item count = 3");

      RGA_Str.Delete (R, 2);
      RunR.Check(RGA_Str.Size (R) = 3, "After delete: size = 3 (tombstone still counts)");

      RGA_Str.Compact (R);
      RunR.Check(RGA_Str.Size (R) = 2, "After compact: size = 2");
      RunR.Check(RGA_Str.Get (R, 1) = 'A', "Compact: Get (1) = 'A'");
      RunR.Check(RGA_Str.Get (R, 2) = 'C', "Compact: Get (2) = 'C'");

      Put_Line ("[Tombstone GC] done.");
   end Test_Tombstone_GC;

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
         RunR.Check(No_Exception,
                "Delta with unseen replica does not raise an exception");
      exception
         when others =>
            RunR.Check(False, "Delta with unseen replica raised an exception");
      end;

      RunR.Check(RGA_Str.Size (B) = 3,
             "After ooo delta B has all 3 elements (got" &
             Natural'Image (RGA_Str.Size (B)) & ")");
      RunR.Check(RGA_Str.Get (B, 1) = 'A', "Ooo delta: Get (1) = 'A'");
      RunR.Check(RGA_Str.Get (B, 2) = 'B', "Ooo delta: Get (2) = 'B'");
      RunR.Check(RGA_Str.Get (B, 3) = 'C', "Ooo delta: Get (3) = 'C'");

      -- Now test with a real state vector that's incomplete (missing replica 1)
      -- This should still work: the missing replica means all its items are newer.
      declare
         use type RGA_Str.RGA;
         C : RGA_Str.RGA (Max_RGA);
      begin
         RGA_Str.Insert (C, 1, (2, 1), 'X');
         RGA_Str.Compute_State_Vector (C, SV, SV_Cnt);
         RunR.Check(SV_Cnt >= 1, "State vector computed");
         declare
            No_Exception : Boolean := True;
         begin
            RGA_Str.Sync_Delta (B, A, SV, SV_Cnt);
            RunR.Check(No_Exception,
                   "Delta with incomplete SV does not raise an exception");
         exception
            when others =>
               RunR.Check(False, "Delta with incomplete SV raised an exception");
         end;
         RunR.Check(RGA_Str.Size (B) = 3,
                "After incomplete SV delta B still has 3 elements (got" &
                Natural'Image (RGA_Str.Size (B)) & ")");
      end;

      Put_Line ("[Out-of-Order Delta Appends] done.");
   end Test_Out_Of_Order_Delta;

begin
   Test_Chaotic_Interleaving;
   Test_Tombstone_Edge_Cases;
   Test_Structural_Splitting;
   Test_Delta_Sync;
   Test_Tombstone_GC;
   Test_Out_Of_Order_Delta;
end Run;
end Test_RGA_Features;
