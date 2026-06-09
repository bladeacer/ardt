with CRDT.Test_Support; use CRDT.Test_Support;
with CRDT.Core;
with CRDT.Rga;
with CRDT.Lww_Element_Sets;
with Ada.Text_IO; use Ada.Text_IO;

package body Test_GoL is

   procedure Run (RunR : in out Runner) is

   procedure Test_GoL_Neighbors is
      Max_Set : constant Positive := 50;

      package Cell_Set is new CRDT.Lww_Element_Sets (Integer, Max_Set);

      use type Cell_Set.LWW_Element_Set;

      S : Cell_Set.LWW_Element_Set (Max_Set);

      function Count_Neighbors (S : Cell_Set.LWW_Element_Set; Row, Col : Integer) return Natural is
         C : Natural := 0;
      begin
         for DR in -1 .. 1 loop
            for DC in -1 .. 1 loop
               if (DR /= 0 or DC /= 0)
                 and then Cell_Set.Contains (S, (Row + DR) * 100 + Col + DC)
               then
                  C := C + 1;
               end if;
            end loop;
         end loop;
         return C;
      end Count_Neighbors;

      procedure Set (S : in out Cell_Set.LWW_Element_Set; R, C : Integer; TS : Natural) is
      begin
         Cell_Set.Add (S, R * 100 + C, (Stamp => TS, Node => 1));
      end Set;
   begin
      New_Line;
      Put_Line ("[Game of Life: Neighbors]");

      --  Blinker pattern (3 cells in a row at row 5, cols 5-7)
      Set (S, 5, 5, 1);
      Set (S, 5, 6, 2);
      Set (S, 5, 7, 3);

      RunR.Check(Count_Neighbors (S, 5, 6) = 2, "Blinker center has 2 neighbors (got" &
             Natural'Image (Count_Neighbors (S, 5, 6)) & ")");
      RunR.Check(Count_Neighbors (S, 4, 6) = 3, "Above blinker center has 3 neighbors (got" &
             Natural'Image (Count_Neighbors (S, 4, 6)) & ")");
      RunR.Check(Count_Neighbors (S, 6, 6) = 3, "Below blinker center has 3 neighbors (got" &
             Natural'Image (Count_Neighbors (S, 6, 6)) & ")");
      RunR.Check(Count_Neighbors (S, 1, 1) = 0, "Corner cell has 0 neighbors (got" &
             Natural'Image (Count_Neighbors (S, 1, 1)) & ")");

      Put_Line ("[Game of Life: Neighbors] done.");
   end Test_GoL_Neighbors;

   procedure Test_GoL_Blinker is
      Max_Set : constant Positive := 50;

      package Cell_Set is new CRDT.Lww_Element_Sets (Integer, Max_Set);

      use type Cell_Set.LWW_Element_Set;

      type Cell_Action is (None, Make_Alive, Make_Dead);

      function Is_Alive (S : Cell_Set.LWW_Element_Set; R, C : Integer) return Boolean is
        (Cell_Set.Contains (S, R * 100 + C));

      function Count_Neighbors (S : Cell_Set.LWW_Element_Set; Row, Col : Integer) return Natural is
         C : Natural := 0;
      begin
         for DR in -1 .. 1 loop
            for DC in -1 .. 1 loop
               if (DR /= 0 or DC /= 0)
                 and then Is_Alive (S, Row + DR, Col + DC)
               then
                  C := C + 1;
               end if;
            end loop;
         end loop;
         return C;
      end Count_Neighbors;

      function Is_Blinker (S : Cell_Set.LWW_Element_Set; R, C : Integer) return Boolean is
        ((R = 5 and C in 5 .. 7) or (R = 6 and C = 6));
   begin
      New_Line;
      Put_Line ("[Game of Life: Blinker]");

       --  Track stamps per row/col encoding
      declare
         Stamp : Natural := 0;
         Cells : Cell_Set.LWW_Element_Set (Max_Set);

         procedure Evolve is
            Actions : array (1 .. 10, 1 .. 10) of Cell_Action := (others => (others => None));
         begin
            for R in 1 .. 10 loop
               for C in 1 .. 10 loop
                  declare
                     Alive     : constant Boolean := Is_Alive (Cells, R, C);
                     Neighbors : constant Natural := Count_Neighbors (Cells, R, C);
                  begin
                     if Alive and (Neighbors < 2 or Neighbors > 3) then
                        Actions (R, C) := Make_Dead;
                     elsif not Alive and Neighbors = 3 then
                        Actions (R, C) := Make_Alive;
                     end if;
                  end;
               end loop;
            end loop;

            for R in 1 .. 10 loop
               for C in 1 .. 10 loop
                  case Actions (R, C) is
                     when Make_Alive =>
                        Stamp := Stamp + 1;
                        Cell_Set.Add (Cells, R * 100 + C, (Stamp => Stamp, Node => 1));
                     when Make_Dead =>
                        Stamp := Stamp + 1;
                        Cell_Set.Remove (Cells, R * 100 + C, (Stamp => Stamp, Node => 1));
                     when None => null;
                  end case;
               end loop;
            end loop;
         end Evolve;
      begin
         --  Initialize blinker: horizontal at row 5, cols 5-7
         Stamp := 1; Cell_Set.Add (Cells, 5 * 100 + 5, (Stamp => 1, Node => 1));
         Stamp := 2; Cell_Set.Add (Cells, 5 * 100 + 6, (Stamp => 2, Node => 1));
         Stamp := 3; Cell_Set.Add (Cells, 5 * 100 + 7, (Stamp => 3, Node => 1));

         RunR.Check(Is_Alive (Cells, 5, 5) and Is_Alive (Cells, 5, 6) and Is_Alive (Cells, 5, 7),
                "Blinker gen 0: horizontal alive");

         --  Evolve to generation 1 (vertical)
         Evolve;
         RunR.Check(not Is_Alive (Cells, 5, 5) and Is_Alive (Cells, 4, 6) and Is_Alive (Cells, 5, 6) and Is_Alive (Cells, 6, 6),
                "Blinker gen 1: vertical alive");

         --  Evolve to generation 2 (horizontal again -- oscillator period 2)
         Evolve;
         RunR.Check(Is_Alive (Cells, 5, 5) and Is_Alive (Cells, 5, 6) and Is_Alive (Cells, 5, 7),
                "Blinker gen 2: back to horizontal");
      end;

      Put_Line ("[Game of Life: Blinker] done.");
   end Test_GoL_Blinker;

   procedure Test_GoL_Matrix_Yjs_Sync is
      Grid_Size : constant := 5;
      Max_Items : constant := 30;

      package Matrix is new CRDT.Lww_Element_Sets (Integer, Max_Items * 2);
      package Rows is new CRDT.Rga (Character, Max_Items, Max_Stride => 10);

      Cells : Matrix.LWW_Element_Set (Matrix.Max_Capacity);
      Grid  : array (1 .. Grid_Size) of Rows.RGA (Max_Items);
      Seq   : Natural := 0;
      Id    : constant CRDT.Core.Replica_Id := 1;
      Stamp : Natural := 0;
   begin
      New_Line;
      Put_Line ("[Game of Life: Matrix <-> Yjs Sync]");

      --  Fill a few cells in the matrix
      for R in 1 .. Grid_Size loop
         for C in 1 .. Grid_Size loop
            Stamp := Stamp + 1;
            if (R + C) mod 2 = 0 then
               Matrix.Add (Cells, R * 100 + C, (Stamp, Id));
            end if;
         end loop;
      end loop;

      --  Sync Matrix -> Yjs (like Sync_Yjs_From_Matrix)
      for R in 1 .. Grid_Size loop
         Rows.Compact (Grid (R));
         loop
            exit when Rows.Size (Grid (R)) = 0;
            Rows.Delete (Grid (R), 1);
            Rows.Compact (Grid (R));
         end loop;
         for C in 1 .. Grid_Size loop
            Seq := Seq + 1;
            Rows.Insert (Grid (R), C, (Id, Seq),
              (if Matrix.Contains (Cells, R * 100 + C) then '#' else '.'));
         end loop;
      end loop;

      --  Read back from Yjs
      declare
         All_Correct : Boolean := True;
      begin
         for R in 1 .. Grid_Size loop
            for C in 1 .. Grid_Size loop
               declare
                  In_Matrix : constant Boolean := Matrix.Contains (Cells, R * 100 + C);
                  In_Yjs    : constant Boolean := Rows.Get (Grid (R), C) = '#';
               begin
                  if In_Matrix /= In_Yjs then
                     All_Correct := False;
                  end if;
               end;
            end loop;
         end loop;
         RunR.Check(All_Correct, "Matrix -> Yjs: all cells match after sync");
      end;

      --  Simulate a second sync (rows now have data): evolve matrix, re-sync
      declare
         Old_Seq : constant Natural := Seq;
      begin
         for R in 1 .. Grid_Size loop
            for C in 1 .. Grid_Size loop
               Stamp := Stamp + 1;
               if (R + C) mod 2 = 0 then
                  Matrix.Remove (Cells, R * 100 + C, (Stamp, Id));
               else
                  Matrix.Add (Cells, R * 100 + C, (Stamp, Id));
               end if;
            end loop;
         end loop;
         for R in 1 .. Grid_Size loop
            Rows.Compact (Grid (R));
            loop
               exit when Rows.Size (Grid (R)) = 0;
               Rows.Delete (Grid (R), 1);
               Rows.Compact (Grid (R));
            end loop;
            for C in 1 .. Grid_Size loop
               Seq := Seq + 1;
               Rows.Insert (Grid (R), C, (Id, Seq),
                 (if Matrix.Contains (Cells, R * 100 + C) then '#' else '.'));
            end loop;
         end loop;
         declare
            Match : Boolean := True;
         begin
            for R in 1 .. Grid_Size loop
               for C in 1 .. Grid_Size loop
                  if Matrix.Contains (Cells, R * 100 + C)
                    /= (Rows.Get (Grid (R), C) = '#')
                  then
                     Match := False;
                  end if;
               end loop;
            end loop;
            RunR.Check(Match, "Matrix -> Yjs: second sync on non-empty rows preserves all cells");
         end;
         RunR.Check(Seq > Old_Seq, "Matrix -> Yjs: seq counter monotonically increases (" &
                Natural'Image (Seq) & " >" & Natural'Image (Old_Seq) & ")");
      end;

      --  Sync back: Yjs -> Matrix (like Sync_Matrix_From_Yjs)
      Matrix.Clear (Cells);
      for R in 1 .. Grid_Size loop
         for C in 1 .. Grid_Size loop
            if Rows.Get (Grid (R), C) = '#' then
               Stamp := Stamp + 1;
               Matrix.Add (Cells, R * 100 + C, (Stamp, Id));
            end if;
         end loop;
      end loop;

      --  Verify round-trip: sync back and compare Matrix vs Yjs
      declare
         All_Agree : Boolean := True;
      begin
         for R in 1 .. Grid_Size loop
            for C in 1 .. Grid_Size loop
               if Matrix.Contains (Cells, R * 100 + C)
                 /= (Rows.Get (Grid (R), C) = '#')
               then
                  All_Agree := False;
               end if;
            end loop;
         end loop;
         RunR.Check(All_Agree, "Yjs -> Matrix: round-trip preserves all cells");
      end;

      Put_Line ("[Game of Life: Matrix <-> Yjs Sync] done.");
   end Test_GoL_Matrix_Yjs_Sync;

   procedure Test_GoL_Convergence is
      Grid_Size : constant := 5;
      Max_Set   : constant := 100;

      package Cell_Set is new CRDT.Lww_Element_Sets (Integer, Max_Set);

      use type Cell_Set.LWW_Element_Set;

      type Cell_Action is (None, Make_Alive, Make_Dead);

      function Is_Alive (S : Cell_Set.LWW_Element_Set; R, C : Integer) return Boolean is
        (Cell_Set.Contains (S, R * 100 + C));

      function Count_Neighbors (S : Cell_Set.LWW_Element_Set; Row, Col : Integer) return Natural is
         C : Natural := 0;
      begin
         for DR in -1 .. 1 loop
            for DC in -1 .. 1 loop
               if (DR /= 0 or DC /= 0)
                 and then Row + DR in 1 .. Grid_Size
                 and then Col + DC in 1 .. Grid_Size
                 and then Is_Alive (S, Row + DR, Col + DC)
               then
                  C := C + 1;
               end if;
            end loop;
         end loop;
         return C;
      end Count_Neighbors;

      procedure Evolve (S : in out Cell_Set.LWW_Element_Set; Stamp : in out Natural; Id : CRDT.Core.Replica_Id) is
         Actions : array (1 .. Grid_Size, 1 .. Grid_Size) of Cell_Action := (others => (others => None));
      begin
         for R in 1 .. Grid_Size loop
            for C in 1 .. Grid_Size loop
               declare
                  Alive     : constant Boolean := Is_Alive (S, R, C);
                  Neighbors : constant Natural := Count_Neighbors (S, R, C);
               begin
                  if Alive and (Neighbors < 2 or Neighbors > 3) then
                     Actions (R, C) := Make_Dead;
                  elsif not Alive and Neighbors = 3 then
                     Actions (R, C) := Make_Alive;
                  end if;
               end;
            end loop;
         end loop;

         for R in 1 .. Grid_Size loop
            for C in 1 .. Grid_Size loop
               case Actions (R, C) is
                  when Make_Alive =>
                     Stamp := Stamp + 1;
                     Cell_Set.Add (S, R * 100 + C, (Stamp, Id));
                  when Make_Dead =>
                     Stamp := Stamp + 1;
                     Cell_Set.Remove (S, R * 100 + C, (Stamp, Id));
                  when None => null;
               end case;
            end loop;
         end loop;
      end Evolve;

      Stamp1 : Natural := 0;
      Stamp2 : Natural := 0;
      Stamp3 : Natural := 0;
      N1 : Cell_Set.LWW_Element_Set (Max_Set);
      N2 : Cell_Set.LWW_Element_Set (Max_Set);
      N3 : Cell_Set.LWW_Element_Set (Max_Set);
   begin
      New_Line;
      Put_Line ("[Game of Life: Convergence]");

      --  All 3 start from same initial state (glider)
      for R in 1 .. Grid_Size loop
         for C in 1 .. Grid_Size loop
            Stamp1 := Stamp1 + 1; Stamp2 := Stamp2 + 1; Stamp3 := Stamp3 + 1;
            Cell_Set.Add (N1, R * 100 + C, (Stamp1, 1));
            Cell_Set.Add (N2, R * 100 + C, (Stamp2, 2));
            Cell_Set.Add (N3, R * 100 + C, (Stamp3, 3));
         end loop;
      end loop;

      --  Evolve independently for 3 generations
      for Gen in 1 .. 3 loop
         Evolve (N1, Stamp1, 1);
         Evolve (N2, Stamp2, 2);
         Evolve (N3, Stamp3, 3);
      end loop;

      --  After independent evolution with the same deterministic rules applied
      --  to the same initial state, all three should still have the same
      --  logical state (same cells alive/dead). Their internal timestamps
      --  differ per replica, but Contains() converges.
      declare
         Same_12 : Boolean := True;
         Same_13 : Boolean := True;
      begin
         for R in 1 .. Grid_Size loop
            for C in 1 .. Grid_Size loop
               if Is_Alive (N1, R, C) /= Is_Alive (N2, R, C) then
                  Same_12 := False;
               end if;
               if Is_Alive (N1, R, C) /= Is_Alive (N3, R, C) then
                  Same_13 := False;
               end if;
            end loop;
         end loop;
         RunR.Check(Same_12, "GoL convergence: N1 = N2 after independent evolution (deterministic rules)");
         RunR.Check(Same_13, "GoL convergence: N1 = N3 after independent evolution (deterministic rules)");
      end;

      --  Merge all three pairwise
      Cell_Set.Merge (N1, N2); Cell_Set.Merge (N2, N1);
      Cell_Set.Merge (N1, N3); Cell_Set.Merge (N3, N1);
      Cell_Set.Merge (N2, N3); Cell_Set.Merge (N3, N2);

      --  After full merge, all must agree on every cell
      declare
         Conv_12 : Boolean := True;
         Conv_23 : Boolean := True;
         Conv_13 : Boolean := True;
      begin
         for R in 1 .. Grid_Size loop
            for C in 1 .. Grid_Size loop
               if Is_Alive (N1, R, C) /= Is_Alive (N2, R, C) then
                  Conv_12 := False;
               end if;
               if Is_Alive (N2, R, C) /= Is_Alive (N3, R, C) then
                  Conv_23 := False;
               end if;
               if Is_Alive (N1, R, C) /= Is_Alive (N3, R, C) then
                  Conv_13 := False;
               end if;
            end loop;
         end loop;
         RunR.Check(Conv_12, "Convergence: N1 = N2 after merge");
         RunR.Check(Conv_23, "Convergence: N2 = N3 after merge");
         RunR.Check(Conv_13, "Convergence: N1 = N3 after merge (transitive)");
      end;

      Put_Line ("[Game of Life: Convergence] done.");
   end Test_GoL_Convergence;

   procedure Test_GoL_Mode_Switch is
      Grid_Size : constant := 5;
      Max_Items : constant := 30;

      package Matrix is new CRDT.Lww_Element_Sets (Integer, Max_Items * 2);
      package Rows is new CRDT.Rga (Character, Max_Items, Max_Stride => 10);

      Cells : Matrix.LWW_Element_Set (Matrix.Max_Capacity);
      Grid  : array (1 .. Grid_Size) of Rows.RGA (Max_Items);
      Seq   : Natural := 0;
      Id    : constant CRDT.Core.Replica_Id := 1;
      Stamp : Natural := 0;

      procedure Sync_To_Yjs is
      begin
         for R in 1 .. Grid_Size loop
            Rows.Compact (Grid (R));
            loop
               exit when Rows.Size (Grid (R)) = 0;
               Rows.Delete (Grid (R), 1);
               Rows.Compact (Grid (R));
            end loop;
            for C in 1 .. Grid_Size loop
               Seq := Seq + 1;
               Rows.Insert (Grid (R), C, (Id, Seq),
                 (if Matrix.Contains (Cells, R * 100 + C) then '#' else '.'));
            end loop;
         end loop;
      end Sync_To_Yjs;

      procedure Sync_To_Matrix is
      begin
         Matrix.Clear (Cells);
         for R in 1 .. Grid_Size loop
            for C in 1 .. Grid_Size loop
               if Rows.Get (Grid (R), C) = '#' then
                  Stamp := Stamp + 1;
                  Matrix.Add (Cells, R * 100 + C, (Stamp, Id));
               end if;
            end loop;
         end loop;
      end Sync_To_Matrix;

      function Cells_Match return Boolean is
      begin
         for R in 1 .. Grid_Size loop
            for C in 1 .. Grid_Size loop
               if Matrix.Contains (Cells, R * 100 + C)
                 /= (Rows.Get (Grid (R), C) = '#')
               then
                  return False;
               end if;
            end loop;
         end loop;
         return True;
      end Cells_Match;

      procedure Toggle_Pattern is
      begin
         for R in 1 .. Grid_Size loop
            for C in 1 .. Grid_Size loop
               Stamp := Stamp + 1;
               if (R + C) mod 2 = 0 then
                  Matrix.Remove (Cells, R * 100 + C, (Stamp, Id));
               else
                  Matrix.Add (Cells, R * 100 + C, (Stamp, Id));
               end if;
            end loop;
         end loop;
      end Toggle_Pattern;
   begin
      New_Line;
      Put_Line ("[Game of Life: Mode Switch]");

      --  Gen 0: initial checkerboard in Matrix
      for R in 1 .. Grid_Size loop
         for C in 1 .. Grid_Size loop
            Stamp := Stamp + 1;
            if (R + C) mod 2 = 0 then
               Matrix.Add (Cells, R * 100 + C, (Stamp, Id));
            end if;
         end loop;
      end loop;

      --  First sync: Matrix -> Yjs (empty rows)
      Sync_To_Yjs;
      RunR.Check(Cells_Match, "Mode switch gen 0: first Matrix -> Yjs sync (empty rows)");
      declare
         Seq_After_First : constant Natural := Seq;
      begin
         RunR.Check(Seq_After_First = Grid_Size * Grid_Size, "Mode switch gen 0: seq = Grid_Size^2 (" &
                Natural'Image (Seq_After_First) & " = " & Natural'Image (Grid_Size * Grid_Size) & ")");
      end;

      --  Gen 1: toggle pattern in Matrix (simulate evolution), re-sync
      Toggle_Pattern;
      Sync_To_Yjs;
      RunR.Check(Cells_Match, "Mode switch gen 1: second Matrix -> Yjs sync (non-empty rows)");
      RunR.Check(Seq = Grid_Size * Grid_Size * 2, "Mode switch gen 1: seq monotonically increased (" &
             Natural'Image (Seq) & ")");

      --  Gen 2: toggle again (simulate evolution), re-sync
      Toggle_Pattern;
      Sync_To_Yjs;
      RunR.Check(Cells_Match, "Mode switch gen 2: third Matrix -> Yjs sync (another toggle)");

      --  Gen 3: round-trip Yjs -> Matrix
      Sync_To_Matrix;
      RunR.Check(Cells_Match, "Mode switch gen 3: Yjs -> Matrix round-trip preserves pattern");

      --  Gen 4: back to Yjs again (full cycle: M -> Y -> M -> Y)
      Sync_To_Yjs;
      RunR.Check(Cells_Match, "Mode switch gen 4: second Yjs -> Matrix sync (full cycle complete)");

      --  Gen 5: toggle and sync one more time to ensure no stale-item accumulation
      Toggle_Pattern;
      Sync_To_Yjs;
      RunR.Check(Cells_Match, "Mode switch gen 5: toggle + re-sync after full cycle (no stale items)");

      Put_Line ("[Game of Life: Mode Switch] done.");
   end Test_GoL_Mode_Switch;

begin
   Test_GoL_Neighbors;
   Test_GoL_Blinker;
   Test_GoL_Matrix_Yjs_Sync;
   Test_GoL_Convergence;
   Test_GoL_Mode_Switch;
end Run;
end Test_GoL;
