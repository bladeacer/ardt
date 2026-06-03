with Ada.Text_IO; use Ada.Text_IO;
with Ada.Characters.Latin_1;
with Ada.Numerics.Discrete_Random;
with CRDT.Core;
with CRDT.Lww_Element_Sets;
with CRDT.Rga;
with VT100;

procedure Demo_Life is

   Grid_Size : constant := 20;
   Box_W     : constant := Grid_Size + 2;
   Sep       : constant := 2;
   Num_Nodes : constant := 3;
   Line_W    : constant := 4 + Num_Nodes * Box_W + (Num_Nodes - 1) * Sep;

   type Cell is record
      Row, Col : Integer;
   end record;

   function Cell_Equal (L, R : Cell) return Boolean is
     (L.Row = R.Row and L.Col = R.Col);

   package Cell_Sets is new CRDT.Lww_Element_Sets
     (Element_Type => Cell,
      Max_Set_Size => Grid_Size * Grid_Size * 3);

   package Char_RGA is new CRDT.Rga
     (Element_Type => Character,
      Max_Items    => Grid_Size * 3,
      Max_Stride   => Grid_Size,
      Max_Replicas => 16);

   subtype RGA_Row is Char_RGA.RGA (Grid_Size * 3);
   type RGA_Grid is array (1 .. Grid_Size) of RGA_Row;

   type Grid_Mode is (Matrix, Yjs_RGA);

   type Node is record
      Cells      : Cell_Sets.LWW_Element_Set (Cell_Sets.Max_Capacity);
      Yjs_Cells  : RGA_Grid;
      Seq        : Natural := 0;
      Clock      : CRDT.Core.Lamport_Time;
      Id         : CRDT.Core.Replica_Id;
      Paused     : Boolean := False;
   end record;

   type App_State is record
      N1, N2, N3   : Node;
      Gen          : Natural := 0;
      Focus        : Integer := 1;
      Cur_R, Cur_C : Integer := 1;
      Partition    : Boolean := False;
      Auto         : Boolean := True;
      Running      : Boolean := True;
      Converged    : Boolean := True;
      Mode         : Grid_Mode := Matrix;
   end record;

   TL : constant String := "+";
   TR : constant String := "+";
   BL : constant String := "+";
   BR : constant String := "+";
   V  : constant String := "|";

   ESC  : constant Character := Ada.Characters.Latin_1.ESC;
   Hide : constant String := ESC & "[?25l";
   Show : constant String := ESC & "[?25h";

   subtype Rand_Range is Integer range 1 .. Grid_Size;
   package Nat_Random is new Ada.Numerics.Discrete_Random (Rand_Range);
   Gen : Nat_Random.Generator;

   function Is_Alive (N : Node; Row, Col : Integer) return Boolean is
     (Cell_Sets.Contains (N.Cells, (Row, Col)));

   procedure Init_Yjs_Row (R : in out RGA_Row; Id : CRDT.Core.Replica_Id; Seq : in out Natural) is
   begin
      for C in 1 .. Grid_Size loop
         Seq := Seq + 1;
         Char_RGA.Insert (R, C, (Id, Seq), '.');
      end loop;
   end Init_Yjs_Row;

   function Yjs_Is_Alive (N : Node; Row, Col : Integer) return Boolean is
     (Char_RGA.Get (N.Yjs_Cells (Row), Col) = '#');

   generic
      with function Cell_Alive (N : Node; Row, Col : Integer) return Boolean;
   function Gen_Count_Neighbors (N : Node; Row, Col : Integer) return Integer;

   function Gen_Count_Neighbors (N : Node; Row, Col : Integer) return Integer is
      C : Integer := 0;
   begin
      for DR in -1 .. 1 loop
         for DC in -1 .. 1 loop
            if (DR /= 0 or DC /= 0)
              and then Row + DR in 1 .. Grid_Size
              and then Col + DC in 1 .. Grid_Size
              and then Cell_Alive (N, Row + DR, Col + DC)
            then
               C := C + 1;
            end if;
         end loop;
      end loop;
      return C;
   end Gen_Count_Neighbors;

   type Cell_Action is (None, Make_Alive, Make_Dead);

   procedure Next_Generation (N : in out Node; M : Grid_Mode) is
      Actions : array (1 .. Grid_Size, 1 .. Grid_Size) of Cell_Action :=
        (others => (others => None));
   begin
      case M is
         when Matrix =>
            declare
               function Count_Neighbors is new Gen_Count_Neighbors (Cell_Alive => Is_Alive);
            begin
               for R in 1 .. Grid_Size loop
                  for C in 1 .. Grid_Size loop
                     declare
                        Alive     : constant Boolean := Is_Alive (N, R, C);
                        Neighbors : constant Integer := Count_Neighbors (N, R, C);
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
            end;
         when Yjs_RGA =>
            declare
               function Count_Neighbors is new Gen_Count_Neighbors (Cell_Alive => Yjs_Is_Alive);
               Grid : array (1 .. Grid_Size, 1 .. Grid_Size) of Boolean;
            begin
               for R in 1 .. Grid_Size loop
                  for C in 1 .. Grid_Size loop
                     Grid (R, C) := Yjs_Is_Alive (N, R, C);
                  end loop;
               end loop;

               for R in 1 .. Grid_Size loop
                  for C in 1 .. Grid_Size loop
                     declare
                        Alive     : constant Boolean := Grid (R, C);
                        Neighbors : constant Integer := Count_Neighbors (N, R, C);
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
                           Char_RGA.Delete (N.Yjs_Cells (R), C);
                           N.Seq := N.Seq + 1;
                           Char_RGA.Insert (N.Yjs_Cells (R), C, (N.Id, N.Seq), '#');
                        when Make_Dead =>
                           Char_RGA.Delete (N.Yjs_Cells (R), C);
                           N.Seq := N.Seq + 1;
                           Char_RGA.Insert (N.Yjs_Cells (R), C, (N.Id, N.Seq), '.');
                        when None => null;
                     end case;
                  end loop;
               end loop;
            end;
      end case;
   end Next_Generation;

   procedure Merge_Nodes (N1, N2 : in out Node; M : Grid_Mode) is
   begin
      case M is
         when Matrix =>
            Cell_Sets.Merge (N1.Cells, N2.Cells);
            Cell_Sets.Merge (N2.Cells, N1.Cells);
         when Yjs_RGA =>
            for R in 1 .. Grid_Size loop
               Char_RGA.Merge (N1.Yjs_Cells (R), N2.Yjs_Cells (R));
               Char_RGA.Merge (N2.Yjs_Cells (R), N1.Yjs_Cells (R));
            end loop;
      end case;
   end Merge_Nodes;

   function Check_Converged (S : App_State) return Boolean is
   begin
      for R in 1 .. Grid_Size loop
         for C in 1 .. Grid_Size loop
            declare
               V1 : constant Boolean := (if S.Mode = Matrix then Is_Alive (S.N1, R, C) else Yjs_Is_Alive (S.N1, R, C));
               V2 : constant Boolean := (if S.Mode = Matrix then Is_Alive (S.N2, R, C) else Yjs_Is_Alive (S.N2, R, C));
               V3 : constant Boolean := (if S.Mode = Matrix then Is_Alive (S.N3, R, C) else Yjs_Is_Alive (S.N3, R, C));
            begin
               if V1 /= V2 or V2 /= V3 then
                  return False;
               end if;
            end;
         end loop;
      end loop;
      return True;
   end Check_Converged;

   procedure Sync_Yjs_From_Matrix (N : in out Node) is
   begin
      for R in 1 .. Grid_Size loop
         Char_RGA.Compact (N.Yjs_Cells (R));
         declare
            Sz : constant Natural := Char_RGA.Size (N.Yjs_Cells (R));
         begin
            for I in 1 .. Sz loop
               Char_RGA.Delete (N.Yjs_Cells (R), 1);
            end loop;
         end;
         Char_RGA.Compact (N.Yjs_Cells (R));
         N.Seq := 0;
         for C in 1 .. Grid_Size loop
            N.Seq := N.Seq + 1;
            Char_RGA.Insert (N.Yjs_Cells (R), C, (N.Id, N.Seq),
              (if Cell_Sets.Contains (N.Cells, (R, C)) then '#' else '.'));
         end loop;
      end loop;
   end Sync_Yjs_From_Matrix;

   procedure Sync_Matrix_From_Yjs (N : in out Node) is
   begin
      Cell_Sets.Clear (N.Cells);
      for R in 1 .. Grid_Size loop
         for C in 1 .. Grid_Size loop
            if Yjs_Is_Alive (N, R, C) then
               N.Clock.Stamp := N.Clock.Stamp + 1;
               Cell_Sets.Add (N.Cells, (R, C), N.Clock);
            end if;
         end loop;
      end loop;
   end Sync_Matrix_From_Yjs;

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
      New_Id3 : constant CRDT.Core.Replica_Id := CRDT.Core.New_Replica_Id;
   begin
      Cell_Sets.Clear (S.N1.Cells);
      Cell_Sets.Clear (S.N2.Cells);
      Cell_Sets.Clear (S.N3.Cells);
      S.N1.Id := New_Id1;
      S.N2.Id := New_Id2;
      S.N3.Id := New_Id3;
      S.N1.Clock := (0, New_Id1);
      S.N2.Clock := (0, New_Id2);
      S.N3.Clock := (0, New_Id3);
      S.N1.Seq := 0;
      S.N2.Seq := 0;
      S.N3.Seq := 0;
      Init_Glider (S.N1, 2, 2);
      Init_Glider (S.N2, 2, 2);
      Init_Glider (S.N3, 2, 2);
      Nat_Random.Reset (Gen, 42);
      for I in 1 .. Grid_Size * 2 loop
         declare
            RR : constant Integer := (Nat_Random.Random (Gen) mod Grid_Size) + 1;
            CC : constant Integer := (Nat_Random.Random (Gen) mod Grid_Size) + 1;
         begin
            S.N1.Clock.Stamp := S.N1.Clock.Stamp + 1;
            Cell_Sets.Add (S.N1.Cells, (RR, CC), S.N1.Clock);
            S.N2.Clock.Stamp := S.N2.Clock.Stamp + 1;
            Cell_Sets.Add (S.N2.Cells, (RR, CC), S.N2.Clock);
            S.N3.Clock.Stamp := S.N3.Clock.Stamp + 1;
            Cell_Sets.Add (S.N3.Cells, (RR, CC), S.N3.Clock);
         end;
      end loop;
      Sync_Yjs_From_Matrix (S.N1);
      Sync_Yjs_From_Matrix (S.N2);
      Sync_Yjs_From_Matrix (S.N3);
      S.Gen := 0;
      S.Cur_R := 1;
      S.Cur_C := 1;
      S.Partition := False;
      S.Auto := True;
      S.Mode := Matrix;
      S.N1.Paused := False;
      S.N2.Paused := False;
      S.N3.Paused := False;
   end Reset_State;

   procedure Toggle_Cell (N : in out Node; Row, Col : Integer; M : Grid_Mode) is
   begin
      case M is
         when Matrix =>
            N.Clock.Stamp := N.Clock.Stamp + 1;
            if Is_Alive (N, Row, Col) then
               Cell_Sets.Remove (N.Cells, (Row, Col), N.Clock);
            else
               Cell_Sets.Add (N.Cells, (Row, Col), N.Clock);
            end if;
         when Yjs_RGA =>
            declare
               Alive : constant Boolean := Yjs_Is_Alive (N, Row, Col);
            begin
               Char_RGA.Delete (N.Yjs_Cells (Row), Col);
               N.Seq := N.Seq + 1;
               Char_RGA.Insert (N.Yjs_Cells (Row), Col, (N.Id, N.Seq), (if Alive then '.' else '#'));
            end;
      end case;
   end Toggle_Cell;

   function Alive_Count (N : Node; M : Grid_Mode) return Natural is
      C : Natural := 0;
   begin
      for R in 1 .. Grid_Size loop
         for C2 in 1 .. Grid_Size loop
            if (if M = Matrix then Is_Alive (N, R, C2) else Yjs_Is_Alive (N, R, C2)) then
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

      procedure Put_Grid_Row (N : Node; Row : Integer; Is_Focused : Boolean) is
      begin
         Put (V);
         for C in 1 .. Grid_Size loop
            declare
               Alive : constant Boolean :=
                 (if S.Mode = Matrix then Is_Alive (N, Row, C) else Yjs_Is_Alive (N, Row, C));
               Ch : constant Character := (if Alive then '*' else '.');
            begin
               if Is_Focused and Row = S.Cur_R and C = S.Cur_C then
                  VT100.Set_Attribute (VT100.Revers);
                  Put (Ch);
                  VT100.Set_Attribute (VT100.Reset);
               else
                  Put (Ch);
               end if;
            end;
         end loop;
         Put (V);
      end Put_Grid_Row;

      Grid_Border : constant String (1 .. Grid_Size) := (others => '-');

   begin
      VT100.Move_Cursor (0, 0);
      Put_Line (TL & (1 .. Line_W - 2 => '=') & TR);
      declare
         Gen_S  : constant String := "Gen:" & Image_Trim (S.Gen);
         P1_S   : constant String := (if S.N1.Paused then "ON" else "OFF");
         P2_S   : constant String := (if S.N2.Paused then "ON" else "OFF");
         P3_S   : constant String := (if S.N3.Paused then "ON" else "OFF");
         Mode_S : constant String := (case S.Mode is when Matrix => "Matrix", when Yjs_RGA => "Yjs_RGA");
         Part_S : constant String := (if S.Partition then "Part:ON" else "Part:OFF");
         Auto_S : constant String := (if S.Auto then "Auto:ON" else "Auto:OFF");
         Foc_S  : constant String := "Focus:" & (case S.Focus is when 1 => "A", when 2 => "B", when others => "C");
         Conv_S : constant String := (if S.Converged then "OK" else "DIVERGED");
         Status : constant String := Gen_S & " Paused:A:" & P1_S & " B:" & P2_S & " C:" & P3_S
           & " Mode:" & Mode_S & " " & Part_S & " " & Auto_S & " " & Foc_S & " " & Conv_S;
      begin
         Put (V);
         Put (Status);
         Put_Line (Pad ("", Line_W - 2 - Status'Length) & V);
      end;
      declare
         Cur_S : constant String := (if S.Focus = 1
           then " [" & Image_Trim (S.Cur_R) & "," & Image_Trim (S.Cur_C) & "]"
           else "");
         P1_Label : constant String := (if S.N1.Paused then " PAUSED" else "");
         P2_Label : constant String := (if S.N2.Paused then " PAUSED" else "");
         P3_Label : constant String := (if S.N3.Paused then " PAUSED" else "");
         Label_A : constant String := " +-- Node A" & P1_Label & Cur_S
           & Pad ("", Box_W - 12 - P1_Label'Length - Cur_S'Length) & "+";
         Label_B : constant String := " +-- Node B" & P2_Label
           & Pad ("", Box_W - 12 - P2_Label'Length) & "+";
         Label_C : constant String := " +-- Node C" & P3_Label
           & Pad ("", Box_W - 12 - P3_Label'Length) & "+";
      begin
         Put (V);
         Put (' ');
         Put (Label_A);
         Put (Pad ("", Sep));
         Put (Label_B);
         Put (Pad ("", Sep));
         Put (Label_C);
         Put_Line (" " & V);
      end;
      for R in 1 .. Grid_Size loop
         Put (V);
         Put (' ');
         Put_Grid_Row (S.N1, R, S.Focus = 1);
         Put (Pad ("", Sep));
         Put_Grid_Row (S.N2, R, S.Focus = 2);
         Put (Pad ("", Sep));
         Put_Grid_Row (S.N3, R, S.Focus = 3);
         Put_Line (" " & V);
      end loop;
      Put (V);
      Put (" +" & Grid_Border & "+");
      Put (Pad ("", Sep));
      Put (" +" & Grid_Border & "+");
      Put (Pad ("", Sep));
      Put (" +" & Grid_Border & "+");
      Put_Line (" " & V);
      declare
         A_Alive : constant String := " Alive:" & Image_Trim (Alive_Count (S.N1, S.Mode));
         B_Alive : constant String := " Alive:" & Image_Trim (Alive_Count (S.N2, S.Mode));
         C_Alive : constant String := " Alive:" & Image_Trim (Alive_Count (S.N3, S.Mode));
         A_Full  : constant String := V & A_Alive & Pad ("", Box_W - 2 - A_Alive'Length) & V;
         B_Full  : constant String := V & B_Alive & Pad ("", Box_W - 2 - B_Alive'Length) & V;
         C_Full  : constant String := V & C_Alive & Pad ("", Box_W - 2 - C_Alive'Length) & V;
      begin
         Put (V);
         Put (' ');
         Put (A_Full);
         Put (Pad ("", Sep));
         Put (B_Full);
         Put (Pad ("", Sep));
         Put (C_Full);
         Put_Line (" " & V);
      end;
      Put_Line (TL & (1 .. Line_W - 2 => '-') & TR);

      declare
         Mode_Label : constant String := (case S.Mode is when Matrix => " Matrix ", when Yjs_RGA => " Yjs_RGA ");
         P1_Label   : constant String := (if S.N1.Paused then "A:Paused" else "A:Running");
         P2_Label   : constant String := (if S.N2.Paused then "B:Paused" else "B:Running");
         P3_Label   : constant String := (if S.N3.Paused then "C:Paused" else "C:Running");
         Title      : constant String := "   Ada CRDT  |  Mode:" & Mode_Label & " |  " & P1_Label & " " & P2_Label & " " & P3_Label & "  ";
      begin
         Put_Line (V & Pad (Title, Line_W - 2) & V);
      end;

      Put (V);
      Put ("["); VT100.Set_Attribute (VT100.Revers); Put ("Space"); VT100.Set_Attribute (VT100.Reset);
      Put ("]Step  [");
      VT100.Set_Attribute (VT100.Revers); Put ("T"); VT100.Set_Attribute (VT100.Reset);
      Put ("]oggle  [");
      VT100.Set_Attribute (VT100.Revers); Put ("Z"); VT100.Set_Attribute (VT100.Reset);
      Put ("]Pause  [");
      VT100.Set_Attribute (VT100.Revers); Put ("P"); VT100.Set_Attribute (VT100.Reset);
      Put ("]artition  [");
      VT100.Set_Attribute (VT100.Revers); Put ("M"); VT100.Set_Attribute (VT100.Reset);
      Put ("]erge  [");
      VT100.Set_Attribute (VT100.Revers); Put ("C"); VT100.Set_Attribute (VT100.Reset);
      Put ("]heck");
      Put_Line (Pad ("", Line_W - 2 - 61) & V);

      Put (V);
      Put ("["); VT100.Set_Attribute (VT100.Revers); Put ("Q"); VT100.Set_Attribute (VT100.Reset);
      Put ("]uit  [");
      VT100.Set_Attribute (VT100.Revers); Put ("A"); VT100.Set_Attribute (VT100.Reset);
      Put ("]uto  [");
      VT100.Set_Attribute (VT100.Revers); Put ("R"); VT100.Set_Attribute (VT100.Reset);
      Put ("]eset  [");
      VT100.Set_Attribute (VT100.Revers); Put ("1/2/3"); VT100.Set_Attribute (VT100.Reset);
      Put ("]Focus  [");
      VT100.Set_Attribute (VT100.Revers); Put ("h/j/k/l"); VT100.Set_Attribute (VT100.Reset);
      Put ("]Move  [");
      VT100.Set_Attribute (VT100.Revers); Put ("Y"); VT100.Set_Attribute (VT100.Reset);
      Put ("]js");
      Put_Line (Pad ("", Line_W - 2 - 59) & V);

      Put_Line (BL & (1 .. Line_W - 2 => '=') & BR);
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
            if not S.N1.Paused then
               Next_Generation (S.N1, S.Mode);
            end if;
            if not S.N2.Paused then
               Next_Generation (S.N2, S.Mode);
            end if;
            if not S.N3.Paused then
               Next_Generation (S.N3, S.Mode);
            end if;
            S.Gen := S.Gen + 1;
            if not S.Partition then
               Merge_Nodes (S.N1, S.N2, S.Mode);
               Merge_Nodes (S.N1, S.N3, S.Mode);
            end if;
            S.Converged := Check_Converged (S);
         when 't' | 'T' =>
            if S.Focus = 1 then
               Toggle_Cell (S.N1, S.Cur_R, S.Cur_C, S.Mode);
            elsif S.Focus = 2 then
               Toggle_Cell (S.N2, S.Cur_R, S.Cur_C, S.Mode);
            else
               Toggle_Cell (S.N3, S.Cur_R, S.Cur_C, S.Mode);
            end if;
            if not S.Partition then
               Merge_Nodes (S.N1, S.N2, S.Mode);
               Merge_Nodes (S.N1, S.N3, S.Mode);
            end if;
            S.Converged := Check_Converged (S);
         when 'z' | 'Z' =>
            if S.Focus = 1 then
               S.N1.Paused := not S.N1.Paused;
            elsif S.Focus = 2 then
               S.N2.Paused := not S.N2.Paused;
            else
               S.N3.Paused := not S.N3.Paused;
            end if;
         when 'p' | 'P' =>
            S.Partition := not S.Partition;
            if not S.Partition then
               Merge_Nodes (S.N1, S.N2, S.Mode);
               Merge_Nodes (S.N1, S.N3, S.Mode);
               S.Converged := Check_Converged (S);
            end if;
         when 'm' | 'M' =>
            Merge_Nodes (S.N1, S.N2, S.Mode);
            Merge_Nodes (S.N1, S.N3, S.Mode);
            S.Converged := Check_Converged (S);
         when 'c' | 'C' =>
            S.Converged := Check_Converged (S);
         when 'a' | 'A' =>
            S.Auto := not S.Auto;
         when 'r' | 'R' =>
            Reset_State (S);
            S.Converged := Check_Converged (S);
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
         when '3' =>
            S.Focus := 3;
         when 'y' | 'Y' =>
            if S.Mode = Matrix then
               S.Mode := Yjs_RGA;
               Sync_Yjs_From_Matrix (S.N1);
               Sync_Yjs_From_Matrix (S.N2);
               Sync_Yjs_From_Matrix (S.N3);
            else
               S.Mode := Matrix;
               Sync_Matrix_From_Yjs (S.N1);
               Sync_Matrix_From_Yjs (S.N2);
               Sync_Matrix_From_Yjs (S.N3);
            end if;
            S.Converged := Check_Converged (S);
         when others => null;
      end case;
   end Handle_Input;

   S : App_State;

begin
   Reset_State (S);
   VT100.Clear_Screen;
   VT100.Move_Cursor (0, 0);
   Put (Hide);
   S.Converged := Check_Converged (S);

   loop
      Draw (S);

      if S.Auto then
         if S.Gen mod 5 = 0 then
            case (S.Gen / 5) mod 3 is
               when 0 => S.N1.Paused := not S.N1.Paused;
               when 1 => S.N2.Paused := not S.N2.Paused;
               when others => S.N3.Paused := not S.N3.Paused;
            end case;
         end if;

         delay 0.15;
         if not S.N1.Paused then
            Next_Generation (S.N1, S.Mode);
         end if;
         if not S.N2.Paused then
            Next_Generation (S.N2, S.Mode);
         end if;
         if not S.N3.Paused then
            Next_Generation (S.N3, S.Mode);
         end if;
         S.Gen := S.Gen + 1;
         if not S.Partition then
            Merge_Nodes (S.N1, S.N2, S.Mode);
            Merge_Nodes (S.N1, S.N3, S.Mode);
         end if;
         S.Converged := Check_Converged (S);
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
