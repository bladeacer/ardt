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
-- This library is simple and rather minimal ANSI/VT100 API wrapper for Ada
package VT100 is

  procedure Reset;

  procedure Line_Wrapping
    (State  : in Boolean);

  procedure Use_Default_Font;

  procedure Use_Alternate_Font;

  procedure Clear_Screen;

  procedure Erase_Line;

  type Direction is (Up, Down, Forward, Backward);

  procedure Erase
    (Where  : in Direction);

  procedure Move_Cursor
    (Line   : in Natural;
     Column : in Natural);

  procedure Move_Cursor
    (Where : Direction;
     By    : in Natural);

  procedure Save_Cursor_Position;

  procedure Restore_Cursor_Position;

  procedure Set_Tab;

  procedure Clear_Tab;

  procedure Clear_All_Tabs;

  procedure Scroll_Screen;

  procedure Scroll_Screen
    (From : in Natural;
     To   : in Natural);

  procedure Scroll_Down;

  procedure Scroll_Down
    (Lines  : in Natural);

  procedure Scroll_Up;

  procedure Scroll_Up
    (Lines  : in Natural);

  type Attribute is (Reset, Bold, Dim, Underline, Blink, Revers, Hidden);

  procedure Set_Attribute
    (This: in Attribute);

  type Color is (Black, Red, Green, Yellow, Blue,
                 Magenta, Cyan, White, Default);

  procedure Set_Foreground_Color
    (This: in Color);

  procedure Set_Background_Color
    (This: in Color);

  procedure Print_Screen;

  procedure Print_Line;

  procedure Print_Log
    (State  : in Boolean);

end VT100;
