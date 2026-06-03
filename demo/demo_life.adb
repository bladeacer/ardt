with Ada.Text_IO; use Ada.Text_IO;
with CRDT.Core;
with CRDT.Lww_Element_Sets;

procedure Demo_Life is

   Grid_Size : constant := 20;

   type Cell is record
      Row, Col : Integer;
   end record;

   function Cell_Equal (L, R : Cell) return Boolean is
     (L.Row = R.Row and L.Col = R.Col);

   package Cell_Sets is new CRDT.Lww_Element_Sets
     (Element_Type => Cell,
      Max_Set_Size => Grid_Size * Grid_Size);

   type Node is record
      Cells : Cell_Sets.LWW_Element_Set (Cell_Sets.Max_Capacity);
      Clock : CRDT.Core.Lamport_Time;
      Id    : CRDT.Core.Replica_Id;
   end record;

   function Is_Alive (N : Node; Row, Col : Integer) return Boolean is
     (Cell_Sets.Contains (N.Cells, (Row, Col)));

   function Count_Neighbors (N : Node; Row, Col : Integer) return Integer
   is
      C : Integer := 0;
   begin
      for DR in -1 .. 1 loop
         for DC in -1 .. 1 loop
            if (DR /= 0 or DC /= 0)
              and then Row + DR in 1 .. Grid_Size
              and then Col + DC in 1 .. Grid_Size
              and then Is_Alive (N, Row + DR, Col + DC)
            then
               C := C + 1;
            end if;
         end loop;
      end loop;
      return C;
   end Count_Neighbors;

   type Cell_Action is (None, Make_Alive, Make_Dead);

   procedure Next_Generation (N : in out Node) is
      Actions : array (1 .. Grid_Size, 1 .. Grid_Size) of Cell_Action :=
        (others => (others => None));
   begin
      for R in 1 .. Grid_Size loop
         for C in 1 .. Grid_Size loop
            declare
               Alive     : Boolean := Is_Alive (N, R, C);
               Neighbors : Integer := Count_Neighbors (N, R, C);
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
                  N.Clock.Stamp := N.Clock.Stamp + 1;
                  Cell_Sets.Add (N.Cells, (R, C), N.Clock);
               when Make_Dead =>
                  N.Clock.Stamp := N.Clock.Stamp + 1;
                  Cell_Sets.Remove (N.Cells, (R, C), N.Clock);
               when None =>
                  null;
            end case;
         end loop;
      end loop;
   end Next_Generation;

   procedure Display (N : Node; Title : String) is
   begin
      Put_Line (Title);
      for R in 1 .. Grid_Size loop
         for C in 1 .. Grid_Size loop
            Put (if Is_Alive (N, R, C) then '*' else '.');
         end loop;
         New_Line;
      end loop;
      New_Line;
   end Display;

   procedure Merge_Nodes (N1, N2 : in out Node) is
   begin
      Cell_Sets.Merge (N1.Cells, N2.Cells);
      Cell_Sets.Merge (N2.Cells, N1.Cells);
   end Merge_Nodes;

   procedure Verify_Convergence (N1, N2 : Node) is
      Same : Boolean := True;
   begin
      for R in 1 .. Grid_Size loop
         for C in 1 .. Grid_Size loop
            if Is_Alive (N1, R, C) /= Is_Alive (N2, R, C) then
               Same := False;
               exit;
            end if;
         end loop;
         exit when not Same;
      end loop;
      if Same then
         Put_Line ("SUCCESS: Both nodes converged to identical state!");
      else
         Put_Line ("FAILURE: Nodes did NOT converge!");
      end if;
   end Verify_Convergence;

   procedure Init_Glider (N : in out Node; Row, Col : Integer) is
   begin
      N.Clock.Stamp := N.Clock.Stamp + 1;
      Cell_Sets.Add (N.Cells, (Row, Col + 1), N.Clock);
      N.Clock.Stamp := N.Clock.Stamp + 1;
      Cell_Sets.Add (N.Cells, (Row + 1, Col + 2), N.Clock);
      N.Clock.Stamp := N.Clock.Stamp + 1;
      Cell_Sets.Add (N.Cells, (Row + 2, Col), N.Clock);
      N.Clock.Stamp := N.Clock.Stamp + 1;
      Cell_Sets.Add (N.Cells, (Row + 2, Col + 1), N.Clock);
      N.Clock.Stamp := N.Clock.Stamp + 1;
      Cell_Sets.Add (N.Cells, (Row + 2, Col + 2), N.Clock);
   end Init_Glider;

   N1, N2 : Node;

begin
   Put_Line ("=== Conway's Game of Life: CRDT Merge Demo ===");
   New_Line;

   N1.Id := CRDT.Core.New_Replica_Id;
   N2.Id := CRDT.Core.New_Replica_Id;
   N1.Clock := (0, N1.Id);
   N2.Clock := (0, N2.Id);

   Init_Glider (N1, 2, 2);
   Init_Glider (N2, 2, 2);

   Display (N1, "Initial state (both nodes identical):");

   for Gen in 1 .. 5 loop
      Next_Generation (N1);
      Next_Generation (N2);
   end loop;

   Put_Line ("=== Cells are identical after 5 generations (no partition) ===");
   Verify_Convergence (N1, N2);
   New_Line;

   Put_Line ("=== NETWORK PARTITION ===");
   Put_Line ("N1: user manually ADDED cell (8, 8)");
   N1.Clock.Stamp := N1.Clock.Stamp + 1;
   Cell_Sets.Add (N1.Cells, (8, 8), N1.Clock);
   Put_Line ("N2: user manually ADDED cell (12, 12)");
   N2.Clock.Stamp := N2.Clock.Stamp + 1;
   Cell_Sets.Add (N2.Cells, (12, 12), N2.Clock);
   Put_Line ("N1: user toggles cell (10, 10) → ALIVE (add)");
   N1.Clock.Stamp := N1.Clock.Stamp + 1;
   Cell_Sets.Add (N1.Cells, (10, 10), N1.Clock);
   Put_Line ("N2: user toggles cell (10, 10) → DEAD (remove)");
   N2.Clock.Stamp := N2.Clock.Stamp + 1;
   Cell_Sets.Remove (N2.Cells, (10, 10), N2.Clock);
   New_Line;

   Display (N1, "N1 state during partition:");
   Display (N2, "N2 state during partition:");

   Put_Line ("=== NETWORK HEALED - MERGING ===");
   Merge_Nodes (N1, N2);
   New_Line;

   Display (N1, "N1 state after merge:");
   Display (N2, "N2 state after merge:");

   Verify_Convergence (N1, N2);
   New_Line;

   Put_Line ("Results:");
   Put_Line ("  Cell (8,8)  present: N1="
     & Boolean'Image (Is_Alive (N1, 8, 8))
     & " N2=" & Boolean'Image (Is_Alive (N2, 8, 8)));
   Put_Line ("  Cell (12,12) present: N1="
     & Boolean'Image (Is_Alive (N1, 12, 12))
     & " N2=" & Boolean'Image (Is_Alive (N2, 12, 12)));
   Put_Line ("  Cell (10,10) present: N1="
     & Boolean'Image (Is_Alive (N1, 10, 10))
     & " N2=" & Boolean'Image (Is_Alive (N2, 10, 10)));
end Demo_Life;
