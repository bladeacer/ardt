with Ada.Strings.Unbounded;

package body CRDT.Test_Support is

   use Ada.Strings.Unbounded;

   ----------
   -- Check --
   ----------

   procedure Check (R : in out Runner; Cond : Boolean; Msg : String) is
   begin
      if Cond then
         R.Pass_Count := R.Pass_Count + 1;
         Ada.Text_IO.Put_Line ("  PASS: " & Msg);
      else
         R.Fail_Count := R.Fail_Count + 1;
         Ada.Text_IO.Put_Line ("  FAIL: " & Msg);
      end if;
   end Check;

   ------------
   -- Passed --
   ------------

   function Passed (R : Runner) return Natural is
   begin
      return R.Pass_Count;
   end Passed;

   ------------
   -- Failed --
   ------------

   function Failed (R : Runner) return Natural is
   begin
      return R.Fail_Count;
   end Failed;

   ------------------------
   -- Print_Summary_Table --
   ------------------------

   procedure Print_Summary_Table
     (To   : Ada.Text_IO.File_Type;
      Cats : Category_Array)
   is
      Cat_W  : constant := 42;
      Tsts_W : constant := 7;
      Stat_W : constant := 8;

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

      procedure Row (Name : String; Count : Natural; Tag : String := "") is
         Nam : constant String := Name & (if Tag'Length > 0 then ": " & Tag else "");
         Cnt : constant String := Rjust (Trim_Image (Count), Tsts_W - 2);
         Sts : constant String := Ljust ("PASS", Stat_W - 2);
      begin
         Ada.Text_IO.Put_Line (To, "  | " & Ljust (Nam, Cat_W - 2) & " | " & Cnt & " | " & Sts & " |");
      end Row;

   begin
      Ada.Text_IO.New_Line (To);
      Ada.Text_IO.Put_Line (To, "  | " & Ljust ("Category", Cat_W - 2) & " | " & Ljust ("Tests", Tsts_W - 2)
                            & " | " & Ljust ("Status", Stat_W - 2) & " |");
      Ada.Text_IO.Put_Line (To, "  |" & (1 .. Cat_W => '-') & "|" & (1 .. Tsts_W => '-') & "|" & (1 .. Stat_W => '-') & "|");

      for C of Cats loop
         Row (To_String (C.Name), C.R.Passed + C.R.Failed,
              (if Length (C.Tag) > 0 then To_String (C.Tag) else ""));
      end loop;

      Ada.Text_IO.Put_Line (To, "  |" & (1 .. Cat_W => '-') & "|" & (1 .. Tsts_W => '-') & "|" & (1 .. Stat_W => '-') & "|");
   end Print_Summary_Table;

end CRDT.Test_Support;
