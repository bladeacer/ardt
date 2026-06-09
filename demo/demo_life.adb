with Ada.Text_IO; use Ada.Text_IO;
with Ada.Characters.Latin_1;
with Ada.Numerics.Discrete_Random;
with Ada.Numerics.Float_Random;
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
      Cells       : Cell_Sets.LWW_Element_Set (Cell_Sets.Max_Capacity);
      Yjs_Cells   : RGA_Grid;
      Seq         : Natural := 0;
      Clock       : CRDT.Core.Lamport_Time;
      Id          : CRDT.Core.Replica_Id;
      Paused      : Boolean := False;
      Pause_Timer : Duration := 0.0;
   end record;

   type App_State is record
      N1, N2, N3   : Node;
      Gen          : Natural := 0;
      Paused       : Boolean := False;
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
   Nat_Gen : Nat_Random.Generator;
   Float_Gen : Ada.Numerics.Float_Random.Generator;

   Quit : Boolean := False;

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

   procedure Sync_Yjs_From_Matrix (N : in out Node);

   procedure Next_Generation (N : in out Node; M : Grid_Mode) is
      Actions : array (1 .. Grid_Size, 1 .. Grid_Size) of Cell_Action :=
        (others => (others => None));
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

      if M = Yjs_RGA then
         Sync_Yjs_From_Matrix (N);
      end if;
   end Next_Generation;

   procedure Merge_Nodes (N1, N2 : in out Node; M : Grid_Mode) is
   begin
      Cell_Sets.Merge (N1.Cells, N2.Cells);
      Cell_Sets.Merge (N2.Cells, N1.Cells);
      if M = Yjs_RGA then
         Sync_Yjs_From_Matrix (N1);
         Sync_Yjs_From_Matrix (N2);
      end if;
   end Merge_Nodes;

   procedure Sync_Yjs_From_Matrix (N : in out Node) is
   begin
      for R in 1 .. Grid_Size loop
         Char_RGA.Compact (N.Yjs_Cells (R));
         loop
            exit when Char_RGA.Size (N.Yjs_Cells (R)) = 0;
            Char_RGA.Delete (N.Yjs_Cells (R), 1);
            Char_RGA.Compact (N.Yjs_Cells (R));
         end loop;
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
      Dt : Duration;
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
      Nat_Random.Reset (Nat_Gen, 42);
      for I in 1 .. Grid_Size * Grid_Size * 3 / 10 - 5 loop
         declare
            RR : constant Integer := (Nat_Random.Random (Nat_Gen) mod Grid_Size) + 1;
            CC : constant Integer := (Nat_Random.Random (Nat_Gen) mod Grid_Size) + 1;
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
      S.Paused := False;
      S.Mode := Matrix;
      Ada.Numerics.Float_Random.Reset (Float_Gen, 42);
      Dt := Duration (Ada.Numerics.Float_Random.Random (Float_Gen) * 5.0);
      S.N1.Pause_Timer := Dt;
      Dt := Duration (Ada.Numerics.Float_Random.Random (Float_Gen) * 5.0);
      S.N2.Pause_Timer := Dt;
      Dt := Duration (Ada.Numerics.Float_Random.Random (Float_Gen) * 5.0);
      S.N3.Pause_Timer := Dt;
   end Reset_State;

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
   begin
      if W = 0 then
         return "";
      end if;
      declare
         P : String (1 .. W) := (others => ' ');
      begin
         if S'Length <= W then
            P (1 .. S'Length) := S;
         end if;
         return P;
      end;
   end Pad;

   procedure Draw (S : App_State) is

      Grid_Border : constant String (1 .. Grid_Size) := (others => '-');

      procedure Put_Cell (N : Node; R, C : Integer) is
      begin
         Put ((if (if S.Mode = Matrix then Is_Alive (N, R, C)
                   else Yjs_Is_Alive (N, R, C)) then '*' else '.'));
      end Put_Cell;

      function Node_Label (N : Node; Tag : Character) return String is
         Tag_Str : constant String (1 .. 2) := " " & Tag;
         P_Str   : constant String := (if N.Paused then " PAUSED" else "");
      begin
         return "+-" & Tag_Str & P_Str & Pad ("", Natural'Max (0, Box_W - 5 - P_Str'Length)) & "+";
      end Node_Label;

   begin
      VT100.Move_Cursor (0, 0);
      Put_Line (TL & (1 .. Line_W - 2 => '=') & TR);
      declare
         Gen_S  : constant String := "Gen:" & Image_Trim (S.Gen);
         Mode_S : constant String := (case S.Mode is when Matrix => "Mode:Matrix",
                                       when Yjs_RGA => "Mode:Yjs_RGA");
         Stat_S : constant String := (if S.Paused then "PAUSED" else "Running");
         Status : constant String := " Ada CRDT | " & Gen_S & " | " & Mode_S
           & " | " & Stat_S;
      begin
         Put (V);
         Put (Status);
         Put_Line (Pad ("", Natural'Max (0, Line_W - 2 - Status'Length)) & V);
      end;
      for R in 1 .. Grid_Size loop
         Put (V);
         Put (' ');
         Put (V);
         for C in 1 .. Grid_Size loop Put_Cell (S.N1, R, C); end loop;
         Put (V);
         Put (Pad ("", Sep));
         Put (V);
         for C in 1 .. Grid_Size loop Put_Cell (S.N2, R, C); end loop;
         Put (V);
         Put (Pad ("", Sep));
         Put (V);
         for C in 1 .. Grid_Size loop Put_Cell (S.N3, R, C); end loop;
         Put (V);
         Put_Line (" " & V);
      end loop;
      Put (V);
      Put (' ');
      Put (Node_Label (S.N1, 'A'));
      Put (Pad ("", Sep));
      Put (Node_Label (S.N2, 'B'));
      Put (Pad ("", Sep));
      Put_Line (Node_Label (S.N3, 'C') & " " & V);
      declare
         A_Alive : constant String := " Alive:" & Image_Trim (Alive_Count (S.N1, S.Mode));
         B_Alive : constant String := " Alive:" & Image_Trim (Alive_Count (S.N2, S.Mode));
         C_Alive : constant String := " Alive:" & Image_Trim (Alive_Count (S.N3, S.Mode));
         A_Full  : constant String := V & A_Alive & Pad ("", Natural'Max (0, Box_W - 2 - A_Alive'Length)) & V;
         B_Full  : constant String := V & B_Alive & Pad ("", Natural'Max (0, Box_W - 2 - B_Alive'Length)) & V;
         C_Full  : constant String := V & C_Alive & Pad ("", Natural'Max (0, Box_W - 2 - C_Alive'Length)) & V;
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
      Put (V);
      Put ("  ["); VT100.Set_Attribute (VT100.Revers); Put ("Q"); VT100.Set_Attribute (VT100.Reset);
      Put ("]uit  [");
      VT100.Set_Attribute (VT100.Revers); Put ("R"); VT100.Set_Attribute (VT100.Reset);
      Put ("]eset  [");
      VT100.Set_Attribute (VT100.Revers); Put ("P"); VT100.Set_Attribute (VT100.Reset);
      Put ("]ause  [");
      VT100.Set_Attribute (VT100.Revers); Put ("M"); VT100.Set_Attribute (VT100.Reset);
      Put ("]ode");
      Put_Line (Pad ("", Natural'Max (0, Line_W - 2 - 35)) & V);
      Put_Line (BL & (1 .. Line_W - 2 => '=') & BR);
      Flush;
   end Draw;

   procedure Handle_Input (S : in out App_State; Ch : Character) is
   begin
      case Ch is
         when 'q' | 'Q' =>
            Quit := True;
         when ASCII.ETX =>
            Quit := True;
         when 'p' | 'P' =>
            S.Paused := not S.Paused;
         when 'r' | 'R' =>
            Reset_State (S);
          when 'm' | 'M' =>
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
             VT100.Clear_Screen;
         when others => null;
      end case;
   end Handle_Input;

   procedure Tick_Pause_Timers (S : in out App_State; Dt : Duration) is
      procedure Tick_Node (N : in out Node) is
      begin
         N.Pause_Timer := N.Pause_Timer - Dt;
         if N.Pause_Timer <= 0.0 then
            N.Paused := not N.Paused;
            N.Pause_Timer := Duration (Ada.Numerics.Float_Random.Random (Float_Gen) * 5.0);
         end if;
      end Tick_Node;
   begin
      Tick_Node (S.N1);
      Tick_Node (S.N2);
      Tick_Node (S.N3);
   end Tick_Pause_Timers;

   Step_Dt : constant Duration := 0.15;

   S : App_State;
   Ch : Character;
   Avail : Boolean;

begin
   Reset_State (S);
   VT100.Clear_Screen;
   VT100.Move_Cursor (0, 0);
   Put (Hide);

   loop
      Draw (S);

      if not S.Paused then
         Tick_Pause_Timers (S, Step_Dt);

         if not S.N1.Paused then
            Next_Generation (S.N1, S.Mode);
         end if;
         if not S.N2.Paused then
            Next_Generation (S.N2, S.Mode);
         end if;
         if not S.N3.Paused then
            Next_Generation (S.N3, S.Mode);
         end if;
         if not S.N1.Paused or not S.N2.Paused or not S.N3.Paused then
            S.Gen := S.Gen + 1;
         end if;

         if not S.N1.Paused and not S.N2.Paused then
            Merge_Nodes (S.N1, S.N2, S.Mode);
         end if;
         if not S.N1.Paused and not S.N3.Paused then
            Merge_Nodes (S.N1, S.N3, S.Mode);
         end if;
         if not S.N2.Paused and not S.N3.Paused then
            Merge_Nodes (S.N2, S.N3, S.Mode);
         end if;

         delay Step_Dt;
      end if;

      for Attempt in 1 .. 10 loop
         begin
            Get_Immediate (Ch, Avail);
            if Avail then
               Handle_Input (S, Ch);
               exit;
            end if;
         end;
         if S.Paused then
            delay 0.01;
         else
            exit;
         end if;
      end loop;

      exit when Quit;
   end loop;

   Put (Show);
   New_Line;
   Put_Line ("Goodbye!");
end Demo_Life;
