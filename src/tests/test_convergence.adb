with CRDT.Test_Support; use CRDT.Test_Support;
with CRDT.Core;
with CRDT.Rga;
with CRDT.Lww_Element_Sets;
with Ada.Text_IO; use Ada.Text_IO;

package body Test_Convergence is

   procedure Run (RunR : in out Runner) is

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

      R1 := Base;
      RGA_Str.Insert (R1, 6, Next_Id (1), ' ');
      RGA_Str.Insert (R1, 7, Next_Id (1), 'W');
      RGA_Str.Insert (R1, 8, Next_Id (1), 'o');
      RGA_Str.Insert (R1, 9, Next_Id (1), 'r');
      RGA_Str.Insert (R1, 10, Next_Id (1), 'l');
      RGA_Str.Insert (R1, 11, Next_Id (1), 'd');

      R2 := Base;
      RGA_Str.Delete (R2, 2);

      R3 := Base;
      RGA_Str.Insert (R3, 2, Next_Id (3), 'X');

      declare
         M : RGA_Str.RGA (Max_RGA) := R1;
      begin
         RGA_Str.Merge (M, R2);
         RGA_Str.Merge (M, R3);
         RunR.Check(RGA_Str.Size (M) >= 5, "Unified state size >= 5 (got" &
                Natural'Image (RGA_Str.Size (M)) & ") -- " & To_String (M));
      end;

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

         declare
            Siz : constant Natural := RGA_Str.Size (M12);
         begin
            RunR.Check(RGA_Str.Size (M21) = Siz
                   and then RGA_Str.Size (M13) = Siz
                   and then RGA_Str.Size (M31) = Siz
                   and then RGA_Str.Size (M23) = Siz
                   and then RGA_Str.Size (M32) = Siz,
                   "All 6 merge orders have same size =" &
                   Natural'Image (Siz));
         end;

         declare
            Tmp : RGA_Str.RGA (Max_RGA) := M12;
         begin
            RGA_Str.Merge (Tmp, M21);
            RunR.Check(RGA_Str.Size (Tmp) = RGA_Str.Size (M12),
                   "Merge(M12, M21) preserves size");
         end;
         declare
            Tmp : RGA_Str.RGA (Max_RGA) := M12;
         begin
            RGA_Str.Merge (Tmp, M31);
            RunR.Check(RGA_Str.Size (Tmp) = RGA_Str.Size (M12),
                   "Merge(M12, M31) preserves size");
         end;
      end;

      Put_Line ("[Three-Way Split Brain] done.");
   end Test_Three_Way_Split;

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

      RGA_Str.Insert (Base, 1, (1, 1), 'H');
      RGA_Str.Insert (Base, 2, (1, 2), 'e');
      RGA_Str.Insert (Base, 3, (1, 3), 'l');
      RGA_Str.Insert (Base, 4, (1, 4), 'l');
      RGA_Str.Insert (Base, 5, (1, 5), 'o');
      RGA_Str.Insert (Base, 6, (1, 6), ' ');

      declare
         A : RGA_Str.RGA (Max_RGA) := Base;
      begin
         RGA_Str.Insert (A, 7, (2, 1), '1');
         RGA_Str.Insert (A, 8, (2, 2), '2');
         RGA_Str.Insert (A, 9, (2, 3), '3');

         declare
            B : RGA_Str.RGA (Max_RGA) := Base;
         begin
            RGA_Str.Insert (B, 7, (3, 1), 'A');
            RGA_Str.Insert (B, 8, (3, 2), 'B');
            RGA_Str.Insert (B, 9, (3, 3), 'C');

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
                  RunR.Check(RGA_Str.Size (M1) >= 12,
                         "Anti-interleaving: M1 size >= 12 (got" & Natural'Image (RGA_Str.Size (M1)) & ")");
                  RunR.Check(RGA_Str.Size (M2) >= 12,
                         "Anti-interleaving: M2 size >= 12 (got" & Natural'Image (RGA_Str.Size (M2)) & ")");

                  RunR.Check(Has_Substr (S1, "H") and Has_Substr (S1, "e")
                         and Has_Substr (S1, "l") and Has_Substr (S1, "o")
                         and Has_Substr (S1, " "),
                         "Anti-interleaving: M1 has all base chars (got """ & S1 & """)");
                  RunR.Check(Has_Substr (S2, "H") and Has_Substr (S2, "e")
                         and Has_Substr (S2, "l") and Has_Substr (S2, "o")
                         and Has_Substr (S2, " "),
                         "Anti-interleaving: M2 has all base chars (got """ & S2 & """)");

                  RunR.Check(Has_Substr (S1, "1") and Has_Substr (S1, "2") and Has_Substr (S1, "3")
                         and Has_Substr (S1, "A") and Has_Substr (S1, "B") and Has_Substr (S1, "C"),
                         "Anti-interleaving: M1 has all 6 inserted chars (got """ & S1 & """)");
                  RunR.Check(Has_Substr (S2, "1") and Has_Substr (S2, "2") and Has_Substr (S2, "3")
                         and Has_Substr (S2, "A") and Has_Substr (S2, "B") and Has_Substr (S2, "C"),
                         "Anti-interleaving: M2 has all 6 inserted chars (got """ & S2 & """)");
               end;
            end;
         end;
      end;

      Put_Line ("[Anti-Interleaving] done.");
   end Test_Anti_Interleaving;

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

      for I in 1 .. 10 loop
         LWW.Add (A, I, (Stamp => I * 100, Node => 1));
         LWW.Add (B, I, (Stamp => I * 100, Node => 1));
         LWW.Add (C, I, (Stamp => I * 100, Node => 1));
      end loop;

      for I in 1 .. 10 loop
         LWW.Add (B, 10 + I, (Stamp => 1000000 + I, Node => 2));
      end loop;

      LWW.Merge (A, B);

      LWW.Add (A, 999, (Stamp => 1, Node => 1));
      RunR.Check(LWW.Contains (A, 999),
             "Clock skew: local add of element 999 with Stamp=1 is present");

      declare
         B_Intact : Boolean := True;
      begin
         for I in 1 .. 10 loop
            if not LWW.Contains (A, 10 + I) then
               B_Intact := False;
               exit;
            end if;
         end loop;
         RunR.Check(B_Intact, "Clock skew: B's high-stamp entries survived merge");
      end;

      declare
         C1 : LWW.LWW_Element_Set (Max_LWW) := C;
         C2 : LWW.LWW_Element_Set (Max_LWW) := C;
      begin
         LWW.Merge (C1, A);
         LWW.Merge (C1, B);

         LWW.Merge (C2, B);
         LWW.Merge (C2, A);

         RunR.Check(C1 = C2, "Clock skew: merge of A and B in any order converges");

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
            RunR.Check(All_Converge, "Clock skew: A and C1 semantically convergent");
         end;
      end;

      Put_Line ("[HLC Clock Skew] done.");
   end Test_HLC_Clock_Skew;

   procedure Test_Tombstone_Saturation is
      Max_Items : constant Positive := 100;

      package RGA_Ch is new CRDT.Rga (Character, Max_Items, Max_Stride => 64);

      RG : RGA_Ch.RGA (Max_Items);
   begin
      New_Line;
      Put_Line ("[Tombstone Saturation]");

      declare
         No_Exception : Boolean := True;
      begin
         for I in 1 .. 90 loop
            RGA_Ch.Insert (RG, RGA_Ch.Size (RG) + 1, (1, I),
                           Character'Val ((I - 1) mod 26 + 65));
         end loop;

         for I in 1 .. 80 loop
            RGA_Ch.Delete (RG, 1);
         end loop;

         RunR.Check(No_Exception, "Tombstone saturation: no exception during fill/delete");
      exception
         when others =>
            RunR.Check(False, "Tombstone saturation: exception raised during fill/delete");
      end;

      RunR.Check(RGA_Ch.Count (RG) >= 80, "Tombstone saturation: Count >= 80 (got" &
             Natural'Image (RGA_Ch.Count (RG)) & ")");
      RunR.Check(RGA_Ch.Size (RG) >= 10, "Tombstone saturation: Size >= 10 (got" &
             Natural'Image (RGA_Ch.Size (RG)) & ")");

      RGA_Ch.Compact (RG);

      RunR.Check(RGA_Ch.Size (RG) >= 10, "Tombstone saturation: after compact Size >= 10 (got" &
             Natural'Image (RGA_Ch.Size (RG)) & ")");
      RunR.Check(RGA_Ch.Count (RG) >= 10, "Tombstone saturation: after compact Count >= 10 (got" &
             Natural'Image (RGA_Ch.Count (RG)) & ")");

      for I in 91 .. 120 loop
         RGA_Ch.Insert (RG, RGA_Ch.Size (RG) + 1, (1, I),
                        Character'Val ((I - 1) mod 26 + 65));
      end loop;

      declare
         No_Exception : Boolean := True;
      begin
         for I in 1 .. RGA_Ch.Size (RG) loop
            declare
               Unused : constant Character := RGA_Ch.Get (RG, I);
            begin
               null;
            end;
         end loop;
         RunR.Check(No_Exception, "Tombstone saturation: no exception during readback");
      exception
         when others =>
            RunR.Check(False, "Tombstone saturation: exception raised during readback");
      end;

      RunR.Check(RGA_Ch.Size (RG) >= 40, "Tombstone saturation: final Size >= 40 (got" &
             Natural'Image (RGA_Ch.Size (RG)) & ")");

      Put_Line ("[Tombstone Saturation] done.");
   end Test_Tombstone_Saturation;

begin
   Test_Three_Way_Split;
   Test_Anti_Interleaving;
   Test_HLC_Clock_Skew;
   Test_Tombstone_Saturation;
end Run;
end Test_Convergence;
