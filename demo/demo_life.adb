with Ada.Text_IO; use Ada.Text_IO;
with Ada.Characters.Latin_1;
with CRDT.Core;
with CRDT.Lww_Element_Sets;
with VT100;

procedure Demo_Life is

   Grid_Size : constant := 20;
   Box_W     : constant := Grid_Size + 2;
   Sep       : constant := 2;
   Line_W    : constant := 4 + 2 * Box_W + Sep;

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

   type App_State is record
      N1, N2        : Node;
      Gen           : Natural := 0;
      Focus         : Integer := 1;
      Cur_R, Cur_C  : Integer := 1;
      Partition     : Boolean := False;
      Auto          : Boolean := False;
      Running       : Boolean := True;
      Converged     : Boolean := True;
   end record;

   TL : constant String := "+";
   TR : constant String := "+";
   BL : constant String := "+";
   BR : constant String := "+";
   V  : constant String := "|";

   ESC  : constant Character := Ada.Characters.Latin_1.ESC;
   Hide : constant String := ESC & "[?25l";
   Show : constant String := ESC & "[?25h";

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
               when None => null;
            end case;
         end loop;
      end loop;
   end Next_Generation;

   procedure Merge_Nodes (N1, N2 : in out Node) is
   begin
      Cell_Sets.Merge (N1.Cells, N2.Cells);
      Cell_Sets.Merge (N2.Cells, N1.Cells);
   end Merge_Nodes;

   function Check_Converged (N1, N2 : Node) return Boolean is
   begin
      for R in 1 .. Grid_Size loop
         for C in 1 .. Grid_Size loop
            if Is_Alive (N1, R, C) /= Is_Alive (N2, R, C) then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Check_Converged;

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

   procedure Reset_State (S : in out App_State) is
      New_Id1 : constant CRDT.Core.Replica_Id := CRDT.Core.New_Replica_Id;
      New_Id2 : constant CRDT.Core.Replica_Id := CRDT.Core.New_Replica_Id;
   begin
      Cell_Sets.Clear (S.N1.Cells);
      Cell_Sets.Clear (S.N2.Cells);
      S.N1.Id := New_Id1;
      S.N2.Id := New_Id2;
      S.N1.Clock := (0, New_Id1);
      S.N2.Clock := (0, New_Id2);
      Init_Glider (S.N1, 2, 2);
      Init_Glider (S.N2, 2, 2);
      S.Gen := 0;
      S.Cur_R := 1;
      S.Cur_C := 1;
      S.Partition := False;
      S.Auto := False;
   end Reset_State;

   function Alive_Count (N : Node) return Natural is
      C : Natural := 0;
   begin
      for R in 1 .. Grid_Size loop
         for C2 in 1 .. Grid_Size loop
            if Is_Alive (N, R, C2) then
               C := C + 1;
            end if;
         end loop;
      end loop;
      return C;
   end Alive_Count;

   function Image_Trim (N : Natural) return String is
      S : constant String := N'Image;
   begin
      return S (S'First + 1 .. S'Last);
   end Image_Trim;

   function Pad (S : String; W : Natural) return String is
      P : String (1 .. W) := (others => ' ');
   begin
      if S'Length <= W then
         P (1 .. S'Length) := S;
      end if;
      return P;
   end Pad;

   procedure Draw (S : App_State) is

      procedure Put_Grid_Row (N : Node; Row : Integer;
                              Is_Focused : Boolean) is
      begin
         Put (V);
         for C in 1 .. Grid_Size loop
            if Is_Focused and Row = S.Cur_R and C = S.Cur_C then
               declare
                  Ch : constant Character :=
                    (if Is_Alive (N, Row, C) then '*' else '.');
               begin
                  VT100.Set_Attribute (VT100.Revers);
                  Put (Ch);
                  VT100.Set_Attribute (VT100.Reset);
               end;
            else
               Put ((if Is_Alive (N, Row, C) then '*' else '.'));
            end if;
         end loop;
         Put (V);
      end Put_Grid_Row;

      Grid_Border : constant String (1 .. Grid_Size) := (others => '-');

   begin
      VT100.Move_Cursor (0, 0);
      --  Line 1: top border
      Put_Line (TL & (1 .. Line_W - 2 => '=') & TR);
      --  Line 2: status
      declare
         Gen_S  : constant String := "Gen:" & Image_Trim (S.Gen);
         Part_S : constant String := (if S.Partition then "Part:ON" else "Part:OFF");
         Foc_S  : constant String := "Focus:" & (case S.Focus is when 1 => "A", when others => "B");
         Auto_S : constant String := (if S.Auto then "Auto:ON" else "Auto:OFF");
         Conv_S : constant String := (if S.Converged then "OK" else "DIVERGED");
         Status : constant String := Gen_S & " " & Part_S & " " & Foc_S & " " & Auto_S & " " & Conv_S;
      begin
         Put (V);
         Put (Status);
         Put_Line (Pad ("", Line_W - 2 - Status'Length) & V);
      end;
      --  Line 3: grid top borders
      declare
         Cur_S : constant String := (if S.Focus = 1
                                     then " [" & Image_Trim (S.Cur_R) & "," & Image_Trim (S.Cur_C) & "]"
                                     else "");
         Label_A : constant String := " +-- Node A" & Cur_S & " " & Pad ("", Box_W - 13 - Cur_S'Length) & "+";
      begin
         Put (V);
         Put (' ');
         Put (Label_A);
         Put (Pad ("", Sep));
         Put (" +-- Node B " & Pad ("", Box_W - 13) & "+");
         Put_Line (" " & V);
      end;
      --  Lines 4-23: grid rows (20)
      for R in 1 .. Grid_Size loop
         Put (V);
         Put (' ');
         Put_Grid_Row (S.N1, R, S.Focus = 1);
         Put (Pad ("", Sep));
         Put_Grid_Row (S.N2, R, S.Focus = 2);
         Put_Line (" " & V);
      end loop;
      --  Line 24: grid bottom
      Put (V);
      Put (" +" & Grid_Border & "+");
      Put (Pad ("", Sep));
      Put (" +" & Grid_Border & "+");
      Put_Line (" " & V);
      --  Line 25: alive counts
      declare
         A_Alive : constant String := " Alive:" & Image_Trim (Alive_Count (S.N1));
         B_Alive : constant String := " Alive:" & Image_Trim (Alive_Count (S.N2));
         A_Full  : constant String := V & A_Alive & Pad ("", Box_W - 2 - A_Alive'Length) & V;
         B_Full  : constant String := V & B_Alive & Pad ("", Box_W - 2 - B_Alive'Length) & V;
      begin
         Put (V);
         Put (' ');
         Put (A_Full);
         Put (Pad ("", Sep));
         Put (B_Full);
         Put_Line (" " & V);
      end;
      --  Line 26: divider
      Put_Line (TL & (1 .. Line_W - 2 => '-') & TR);
      --  Lines 27-28: controls
      Put_Line (V & Pad ("[Space]Step  [T]oggle  [P]artition  [M]erge  [C]heck",
                         Line_W - 2) & V);
      Put_Line (V & Pad ("[Q]uit  [A]uto  [R]eset  [1/2]Focus  [h/j/k/l]Move",
                         Line_W - 2) & V);
      --  Line 29: bottom border
      Put_Line (BL & (1 .. Line_W - 2 => '=') & BR);
      --  Auto-run indicator
      if S.Auto then
         Put (V & Pad ("(* auto-stepping *)", Line_W - 2) & V & ASCII.CR);
      end if;
      Flush;
   end Draw;

   procedure Handle_Input (S : in out App_State; Ch : Character) is
   begin
      case Ch is
         when 'q' | 'Q' =>
            S.Running := False;
         when ' ' =>
            Next_Generation (S.N1);
            Next_Generation (S.N2);
            S.Gen := S.Gen + 1;
            if not S.Partition then
               Merge_Nodes (S.N1, S.N2);
            end if;
            S.Converged := Check_Converged (S.N1, S.N2);
         when 't' | 'T' =>
            if S.Focus = 1 then
               S.N1.Clock.Stamp := S.N1.Clock.Stamp + 1;
               if Is_Alive (S.N1, S.Cur_R, S.Cur_C) then
                  Cell_Sets.Remove (S.N1.Cells, (S.Cur_R, S.Cur_C), S.N1.Clock);
               else
                  Cell_Sets.Add (S.N1.Cells, (S.Cur_R, S.Cur_C), S.N1.Clock);
               end if;
            else
               S.N2.Clock.Stamp := S.N2.Clock.Stamp + 1;
               if Is_Alive (S.N2, S.Cur_R, S.Cur_C) then
                  Cell_Sets.Remove (S.N2.Cells, (S.Cur_R, S.Cur_C), S.N2.Clock);
               else
                  Cell_Sets.Add (S.N2.Cells, (S.Cur_R, S.Cur_C), S.N2.Clock);
               end if;
            end if;
            if not S.Partition then
               Merge_Nodes (S.N1, S.N2);
            end if;
            S.Converged := Check_Converged (S.N1, S.N2);
         when 'p' | 'P' =>
            S.Partition := not S.Partition;
            if not S.Partition then
               Merge_Nodes (S.N1, S.N2);
               S.Converged := Check_Converged (S.N1, S.N2);
            end if;
         when 'm' | 'M' =>
            Merge_Nodes (S.N1, S.N2);
            S.Converged := Check_Converged (S.N1, S.N2);
         when 'c' | 'C' =>
            S.Converged := Check_Converged (S.N1, S.N2);
         when 'a' | 'A' =>
            S.Auto := not S.Auto;
         when 'r' | 'R' =>
            Reset_State (S);
            S.Converged := Check_Converged (S.N1, S.N2);
         when 'h' | 'H' =>
            if S.Cur_C > 1 then
               S.Cur_C := S.Cur_C - 1;
            end if;
         when 'l' | 'L' =>
            if S.Cur_C < Grid_Size then
               S.Cur_C := S.Cur_C + 1;
            end if;
         when 'k' | 'K' =>
            if S.Cur_R > 1 then
               S.Cur_R := S.Cur_R - 1;
            end if;
         when 'j' | 'J' =>
            if S.Cur_R < Grid_Size then
               S.Cur_R := S.Cur_R + 1;
            end if;
         when '1' =>
            S.Focus := 1;
         when '2' =>
            S.Focus := 2;
         when others => null;
      end case;
   end Handle_Input;

   S : App_State;

begin
   Reset_State (S);
   VT100.Clear_Screen;
   VT100.Move_Cursor (0, 0);
   Put (Hide);
   S.Converged := Check_Converged (S.N1, S.N2);

   loop
      Draw (S);

      if S.Auto then
         delay 0.15;
         Next_Generation (S.N1);
         Next_Generation (S.N2);
         S.Gen := S.Gen + 1;
         if not S.Partition then
            Merge_Nodes (S.N1, S.N2);
         end if;
         S.Converged := Check_Converged (S.N1, S.N2);
      end if;

      for Attempt in 1 .. 10 loop
         declare
            Ch : Character;
            Avail : Boolean;
         begin
            Get_Immediate (Ch, Avail);
            if Avail then
               Handle_Input (S, Ch);
               exit;
            end if;
         end;
         if not S.Auto then
            exit;
         end if;
         delay 0.01;
      end loop;

      exit when not S.Running;
   end loop;

   Put (Show);
   New_Line;
   Put_Line ("Goodbye!");
end Demo_Life;
