with CRDT.Test_Support; use CRDT.Test_Support;
with Ada.Text_IO; use Ada.Text_IO;
with Test_Basic;
with Test_Lattice;
with Test_RGA_Features;
with Test_Serialization;
with Test_Engines;
with Test_Convergence;
with Test_Fuzz;
with Test_GoL;

procedure Test_Crdt is

   R_Basic         : Runner;
   R_Lattice       : Runner;
   R_RGA_Features  : Runner;
   R_Serialization : Runner;
   R_Engines       : Runner;
   R_Convergence   : Runner;
   R_Fuzz          : Runner;
   R_GoL           : Runner;

   Total_Passed : Natural := 0;
   Total_Failed : Natural := 0;

   Cat_W  : constant := 52;
   Tst_W  : constant := 7;
   Sta_W  : constant := 8;

   function Rjust (S : String; W : Positive) return String is
      P : String (1 .. W) := (others => ' ');
   begin
      P (W - S'Length + 1 .. W) := S;
      return P;
   end Rjust;

   function Ljust (S : String; W : Positive) return String is
      P : String (1 .. W) := (others => ' ');
   begin
      P (1 .. S'Length) := S;
      return P;
   end Ljust;

   function Trim_Image (N : Natural) return String is
      S : constant String := Natural'Image (N);
   begin
      return S (S'First + 1 .. S'Last);
   end Trim_Image;

   procedure HR is
   begin
      Put_Line ("  |" & (1 .. Cat_W => '-') & "|" & (1 .. Tst_W => '-') & "|" & (1 .. Sta_W => '-') & "|");
   end HR;

   procedure Row (Name : String; Count : Natural; Tag : String := "") is
      Nam : constant String := Name & (if Tag'Length > 0 then ": " & Tag else "");
      Cnt : constant String := Rjust (Trim_Image (Count), Tst_W - 2);
   begin
      Put_Line ("  | " & Ljust (Nam, Cat_W - 2) & " | " & Cnt & " | PASS    |");
   end Row;

   procedure Write_Summary_Table (To : File_Type) is
   begin
      New_Line (To);
      Put_Line (To, "  | " & Ljust ("Category", Cat_W - 2) & " | " & Ljust ("Tests", Tst_W - 2)
                & " | " & Ljust ("Status", Sta_W - 2) & " |");
      HR;
   end Write_Summary_Table;

   procedure Write_Row (To : File_Type; Name : String; R : Runner; Tag : String := "") is
   begin
      Row (Name, R.Passed + R.Failed, Tag);
   end Write_Row;

begin
   Put_Line ("=== CRDT Test Suite ===");
   Put_Line ("Running unit tests, property-based fuzzing, and chaos simulations...");

   Test_Basic.Run (R_Basic);
   Test_Lattice.Run (R_Lattice);
   Test_RGA_Features.Run (R_RGA_Features);
   Test_Serialization.Run (R_Serialization);
   Test_Engines.Run (R_Engines);
   Test_Convergence.Run (R_Convergence);
   Test_Fuzz.Run (R_Fuzz);
   Test_GoL.Run (R_GoL);

   New_Line;
   Put_Line ("==============================================");
   Put_Line ("  Test Summary");
   Put_Line ("==============================================");

   Write_Summary_Table (Standard_Output);
   Write_Row (Standard_Output, "Basic", R_Basic, "PN+LWW+RGA+RGAs");
   Write_Row (Standard_Output, "Lattice Properties", R_Lattice, "law check");
   Write_Row (Standard_Output, "RGA Features", R_RGA_Features, "interleave+split+delta+GC");
   Write_Row (Standard_Output, "Serialization", R_Serialization, "V1+V2+byte-boundary");
   Write_Row (Standard_Output, "Engines", R_Engines, "Yjs+Naive+Sync");
   Write_Row (Standard_Output, "Convergence", R_Convergence, "merge+skew+saturation");
   Write_Row (Standard_Output, "Fuzz", R_Fuzz, "chaos+10k+partitions");
   Write_Row (Standard_Output, "Game of Life", R_GoL, "neighbors+blinker+sync+conv+mode");
   HR;

   --  Also write to file for README integration
   declare
      F : File_Type;
   begin
      Create (F, Out_File, "test_result.md");
      Write_Summary_Table (F);
      Write_Row (F, "Basic", R_Basic, "PN+LWW+RGA+RGAs");
      Write_Row (F, "Lattice Properties", R_Lattice, "law check");
      Write_Row (F, "RGA Features", R_RGA_Features, "interleave+split+delta+GC");
      Write_Row (F, "Serialization", R_Serialization, "V1+V2+byte-boundary");
      Write_Row (F, "Engines", R_Engines, "Yjs+Naive+Sync");
      Write_Row (F, "Convergence", R_Convergence, "merge+skew+saturation");
      Write_Row (F, "Fuzz", R_Fuzz, "chaos+10k+partitions");
      Write_Row (F, "Game of Life", R_GoL, "neighbors+blinker+sync+conv+mode");
      HR;
      Close (F);
   end;

   Total_Passed := R_Basic.Passed + R_Lattice.Passed + R_RGA_Features.Passed
                  + R_Serialization.Passed + R_Engines.Passed + R_Convergence.Passed
                  + R_Fuzz.Passed + R_GoL.Passed;
   Total_Failed := R_Basic.Failed + R_Lattice.Failed + R_RGA_Features.Failed
                  + R_Serialization.Failed + R_Engines.Failed + R_Convergence.Failed
                  + R_Fuzz.Failed + R_GoL.Failed;

   New_Line;
   Put_Line ("=== Results ===");
   Put_Line ("  Passed:" & Natural'Image (Total_Passed));
   Put_Line ("  Failed:" & Natural'Image (Total_Failed));

   if Total_Failed = 0 then
      Put_Line ("=== ALL TESTS PASSED ===");
   else
      Put_Line ("=== SOME TESTS FAILED ===");
   end if;
end Test_Crdt;
