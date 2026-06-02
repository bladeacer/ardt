package Ardt.Pn_Counters with
  SPARK_Mode
is

   subtype Counter_Range is Natural;

   type PN_Counter is private with
    Default_Initial_Condition;

   function Value (C : PN_Counter) return Integer;

   function Can_Increment (C : PN_Counter; By : Counter_Range := 1)
                           return Boolean with
     Inline;

   function Can_Decrement (C : PN_Counter; By : Counter_Range := 1)
                           return Boolean with
     Inline;

   procedure Increment (C   : in out PN_Counter;
                        By  : Counter_Range := 1) with
     Pre  => Can_Increment (C, By);

   procedure Decrement (C   : in out PN_Counter;
                        By  : Counter_Range := 1) with
     Pre  => Can_Decrement (C, By);

   procedure Merge (Target : in out PN_Counter;
                    Source : PN_Counter);

private

   type PN_Counter is record
      P : Counter_Range := 0;
      N : Counter_Range := 0;
   end record;

end Ardt.Pn_Counters;
