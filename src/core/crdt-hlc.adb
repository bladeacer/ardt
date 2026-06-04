with Ada.Calendar;

package body CRDT.HLC is

   use Ada.Calendar;
   use type Core.Replica_Id;

   ---------------
   --  Ordering --
   ---------------

   function "<" (Left, Right : HLC_Time) return Boolean is
   begin
      if Left.Wall < Right.Wall then
         return True;
      elsif Left.Wall > Right.Wall then
         return False;
      elsif Left.Log < Right.Log then
         return True;
      elsif Left.Log > Right.Log then
         return False;
      else
         return Left.Node < Right.Node;
      end if;
   end "<";

   function "=" (Left, Right : HLC_Time) return Boolean is
   begin
      return Left.Wall = Right.Wall
        and then Left.Log = Right.Log
        and then Left.Node = Right.Node;
   end "=";

   function ">" (Left, Right : HLC_Time) return Boolean is
   begin
      return not (Left < Right or else Left = Right);
   end ">";

   ---------------
   --  Create   --
   ---------------

   function Create (Node : Core.Replica_Id) return Instance is
   begin
      return Instance'(Wall => Clock,
                       Node => Node,
                       Log  => 0);
   end Create;

   ---------------
   --  Tick     --
   ---------------

   procedure Tick (Clock : in out Instance) is
      Now_Time : constant Ada.Calendar.Time := Ada.Calendar.Clock;
   begin
      if Now_Time > Clock.Wall then
         Clock.Wall := Now_Time;
         Clock.Log := 0;
      else
         Clock.Log := Clock.Log + 1;
      end if;
   end Tick;

   ---------------
   --  Recv     --
   ---------------

   procedure Recv (Clock : in out Instance; Remote : HLC_Time) is
      Now_Time : constant Ada.Calendar.Time := Ada.Calendar.Clock;
   begin
      if Now_Time > Clock.Wall and then Now_Time > Remote.Wall then
         Clock.Wall := Now_Time;
         Clock.Log := 0;
      elsif Clock.Wall > Remote.Wall then
         Clock.Log := Clock.Log + 1;
      elsif Remote.Wall > Clock.Wall then
         Clock.Wall := Remote.Wall;
         Clock.Log := Remote.Log + 1;
      else
         -- Equal wall times
         Clock.Log := Natural'Max (Clock.Log, Remote.Log) + 1;
      end if;
   end Recv;

end CRDT.HLC;
