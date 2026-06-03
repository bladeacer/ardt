------------------------------------------------------------------------------
-- EMAIL: <darkestkhan@gmail.com>                                           --
-- License: ISC License (see COPYING file)                                  --
--                                                                          --
--                    Copyright © 2011 - 2015 darkestkhan                   --
------------------------------------------------------------------------------
-- Permission to use, copy, modify, and/or distribute this software for any --
-- purpose with or without fee is hereby granted, provided that the above   --
-- copyright notice and this permission notice appear in all copies.        --
--                                                                          --
-- The software is provided "as is" and the author disclaims all warranties --
-- with regard to this software including all implied warranties of         --
-- merchantability and fitness. In no event shall the author be liable for  --
-- any special, direct, indirect, or consequential damages or any damages   --
-- whatsoever resulting from loss of use, data or profits, whether in an    --
-- action of contract, negligence or other tortious action, arising out of  --
-- or in connection with the use or performance of this software.           --
------------------------------------------------------------------------------
with Ada.Text_IO;
with Ada.Characters.Latin_1;
package body VT100 is

  package ASCII renames Ada.Characters.Latin_1;

  function Nat_Img
    (N: in Natural) return String
  is
    str: constant String := Natural'Image (N);
  begin
    return str (2 .. str'Last);
  end Nat_Img;

  procedure Reset
  is
  begin
    Ada.Text_IO.Put
      (File => Ada.Text_IO.Standard_Output,
       Item => ASCII.ESC & "c");
  end Reset;

  procedure Line_Wrapping
    (State  : in Boolean)
  is
  begin
    case State is
      when False =>
        Ada.Text_IO.Put
          (File => Ada.Text_IO.Standard_Output,
           Item => ASCII.ESC & "[7l");
      when True =>
        Ada.Text_IO.Put
          (File => Ada.Text_IO.Standard_Output,
           Item => ASCII.ESC & "[7h");
    end case;
  end Line_Wrapping;

  procedure Use_Default_Font
  is
  begin
    Ada.Text_IO.Put
      (File => Ada.Text_IO.Standard_Output,
       Item => ASCII.ESC & "(");
  end Use_Default_Font;

  procedure Use_Alternate_Font
  is
  begin
    Ada.Text_IO.Put
      (File => Ada.Text_IO.Standard_Output,
       Item => ASCII.ESC & ")");
  end Use_Alternate_Font;

  procedure Clear_Screen
  is
  begin
    Ada.Text_IO.Put
      (File => Ada.Text_IO.Standard_Output,
       Item => ASCII.ESC & "[2J");
  end Clear_Screen;

  procedure Erase_Line
  is
  begin
    Ada.Text_IO.Put
      (File => Ada.Text_IO.Standard_Output,
       Item => ASCII.ESC & "[2K");
  end Erase_Line;

  procedure Erase
    (Where  : in Direction)
  is
  begin
    case Where is
      when Up       =>
        Ada.Text_IO.Put
          (File => Ada.Text_IO.Standard_Output,
           Item => ASCII.ESC & "[1J");
      when Down     =>
        Ada.Text_IO.Put
          (File => Ada.Text_IO.Standard_Output,
           Item => ASCII.ESC & "[J");
      when Forward  =>
        Ada.Text_IO.Put
          (File => Ada.Text_IO.Standard_Output,
           Item => ASCII.ESC & "[K");
      when Backward =>
        Ada.Text_IO.Put
          (File => Ada.Text_IO.Standard_Output,
           Item => ASCII.ESC & "[1K");
    end case;
  end Erase;

  procedure Move_Cursor
    (Line   : in Natural;
     Column : in Natural)
  is
  begin
    Ada.Text_IO.Put
      (File => Ada.Text_IO.Standard_Output,
       Item => ASCII.ESC & "[" & Nat_Img (Line) & ";" & Nat_Img (Column) & "H");
  end Move_Cursor;

  procedure Move_Cursor
    (Where : in Direction;
     By    : in Natural)
  is
  begin
    if By > 0 then
      case Where is
        when Up =>
          Ada.Text_IO.Put
            (File => Ada.Text_IO.Standard_Output,
             Item => ASCII.ESC & "[" & Nat_Img (By) & "A");
        when Down =>
          Ada.Text_IO.Put
            (File => Ada.Text_IO.Standard_Output,
             Item => ASCII.ESC & "[" & Nat_Img (By) & "B");
        when Forward =>
          Ada.Text_IO.Put
            (File => Ada.Text_IO.Standard_Output,
             Item => ASCII.ESC & "[" & Nat_Img (By) & "C");
        when Backward =>
          Ada.Text_IO.Put
            (File => Ada.Text_IO.Standard_Output,
             Item => ASCII.ESC & "[" & Nat_Img (By) & "D");
      end case;
    end if;
  end Move_Cursor;

  procedure Save_Cursor_Position
  is
  begin
    Ada.Text_IO.Put
      (File => Ada.Text_IO.Standard_Output,
       Item => ASCII.ESC & "[s");
  end Save_Cursor_Position;

  procedure Restore_Cursor_Position
  is
  begin
    Ada.Text_IO.Put
      (File => Ada.Text_IO.Standard_Output,
       Item => ASCII.ESC & "[u");
  end Restore_Cursor_Position;

  procedure Set_Tab
  is
  begin
    Ada.Text_IO.Put
      (File => Ada.Text_IO.Standard_Output,
       Item => ASCII.ESC & "H");
  end Set_Tab;

  procedure Clear_Tab
  is
  begin
    Ada.Text_IO.Put
      (File => Ada.Text_IO.Standard_Output,
       Item => ASCII.ESC & "[g");
  end Clear_Tab;

  procedure Clear_All_Tabs
  is
  begin
    Ada.Text_IO.Put
      (File => Ada.Text_IO.Standard_Output,
       Item => ASCII.ESC & "[3g");
  end Clear_All_Tabs;

  procedure Scroll_Screen
  is
  begin
    Ada.Text_IO.Put
      (File => Ada.Text_IO.Standard_Output,
       Item => ASCII.ESC & "[r");
  end Scroll_Screen;

  procedure Scroll_Screen
    (From : in Natural;
     To   : in Natural)
  is
  begin
    Ada.Text_IO.Put
      (File => Ada.Text_IO.Standard_Output,
       Item => ASCII.ESC & "[" & Nat_Img (N => From) & ";" &
               Nat_Img (N => To) & "r");
  end Scroll_Screen;

  procedure Scroll_Down
  is
  begin
    Ada.Text_IO.Put
      (File => Ada.Text_IO.Standard_Output,
       Item => ASCII.ESC & "D");
  end Scroll_Down;

  procedure Scroll_Down
    (Lines  : in Natural)
  is
  begin
    if Lines > 0 then
      for I in 1 .. Lines loop
        Scroll_Down;
      end loop;
    end if;
  end Scroll_Down;

  procedure Scroll_Up
  is
  begin
    Ada.Text_IO.Put
      (File => Ada.Text_IO.Standard_Output,
       Item => ASCII.ESC & "H");
  end Scroll_Up;

  procedure Scroll_Up
    (Lines  : in Natural)
  is
  begin
    if Lines > 0 then
      for I in 1 .. Lines loop
        Scroll_Up;
      end loop;
    end if;
  end Scroll_Up;

  procedure Set_Attribute
    (This: in Attribute)
  is
    C: Character;
  begin
    case This is
      when Reset      => C := '0';
      when Bold       => C := '1';
      when Dim        => C := '2';
      when Underline  => C := '3';
      when Blink      => C := '4';
      when Revers     => C := '5';
      when Hidden     => C := '6';
    end case;
    Ada.Text_IO.Put
      (File => Ada.Text_IO.Standard_Output,
       Item => ASCII.ESC & '[' & C & 'm');
  end Set_Attribute;

  procedure Set_Background_Color
    (This: in Color)
  is
    C: Character;
  begin
    case This is
      when Black    => C := '0';
      when Red      => C := '1';
      when Green    => C := '2';
      when Yellow   => C := '3';
      when Blue     => C := '4';
      when Magenta  => C := '5';
      when Cyan     => C := '6';
      when White    => C := '7';
      when Default  => C := '9';
    end case;
    Ada.Text_IO.Put
      (File => Ada.Text_IO.Standard_Output,
       Item => ASCII.ESC & "[4" & C & 'm');
  end Set_Background_Color;

  procedure Set_Foreground_Color
    (This: in Color)
  is
    C: Character;
  begin
    case This is
      when Black    => C := '0';
      when Red      => C := '1';
      when Green    => C := '2';
      when Yellow   => C := '3';
      when Blue     => C := '4';
      when Magenta  => C := '5';
      when Cyan     => C := '6';
      when White    => C := '7';
      when Default  => C := '9';
    end case;
    Ada.Text_IO.Put
      (File => Ada.Text_IO.Standard_Output,
       Item => ASCII.ESC & "[3" & C & 'm');
  end Set_Foreground_Color;

  procedure Print_Screen
  is
  begin
    Ada.Text_IO.Put
      (File => Ada.Text_IO.Standard_Output,
       Item => ASCII.ESC & "[i");
  end Print_Screen;

  procedure Print_Line
  is
  begin
    Ada.Text_IO.Put
      (File => Ada.Text_IO.Standard_Output,
       Item => ASCII.ESC & "[1i");
  end Print_Line;

  procedure Print_Log
    (State  : in Boolean)
  is
  begin
    case State is
      when False =>
        Ada.Text_IO.Put
          (File => Ada.Text_IO.Standard_Output,
           Item => ASCII.ESC & "[4i");
      when True =>
        Ada.Text_IO.Put
          (File => Ada.Text_IO.Standard_Output,
           Item => ASCII.ESC & "[5i");
    end case;
  end Print_Log;

end VT100;
