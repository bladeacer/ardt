with Ada.Text_IO;
with Ada.Strings.Unbounded;

package CRDT.Test_Support is

   type Runner is tagged limited private;

   procedure Check (R : in out Runner; Cond : Boolean; Msg : String);

   function Passed (R : Runner) return Natural;
   function Failed (R : Runner) return Natural;

   type Category_Entry is record
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Tag  : Ada.Strings.Unbounded.Unbounded_String;
      R    : access Runner'Class;
   end record;

   type Category_Array is array (Positive range <>) of Category_Entry;

   procedure Print_Summary_Table
     (To   : Ada.Text_IO.File_Type;
      Cats : Category_Array);

private

   type Runner is tagged limited record
      Pass_Count : Natural := 0;
      Fail_Count : Natural := 0;
   end record;

end CRDT.Test_Support;
