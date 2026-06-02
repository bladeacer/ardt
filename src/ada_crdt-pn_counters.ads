--  PN-Counter with per-replica actor map.
--  Tracks increments (P) and decrements (N) for each replica independently.
--  Fixed memory: 3 replicas = 3 slots regardless of millions of ops.
--  Value = sum(P) - sum(N).
with Ada_CRDT.Core;

package Ada_CRDT.Pn_Counters with
  SPARK_Mode
is

   subtype Counter_Range is Natural;

   type PN_Counter (Max_Actors : Positive) is private with
     Default_Initial_Condition;

   --  Current value of the counter (may be negative).
   function Value (C : PN_Counter) return Integer;

   pragma Warnings (Off, "unused variable");
   function Can_Increment (C : PN_Counter; By : Counter_Range := 1)
                             return Boolean;

   function Can_Decrement (C : PN_Counter; By : Counter_Range := 1)
                             return Boolean;
   pragma Warnings (On, "unused variable");

   --  Increment the counter by By for the given Actor (replica).
   --  Creates a new actor entry if this is the first operation from
   --  that replica.
   procedure Increment (C     : in out PN_Counter;
                        By    : Counter_Range := 1;
                        Actor : Core.Replica_Id) with
     Pre => Can_Increment (C, By);

   --  Decrement the counter by By for the given Actor (replica).
   procedure Decrement (C     : in out PN_Counter;
                        By    : Counter_Range := 1;
                        Actor : Core.Replica_Id) with
     Pre => Can_Decrement (C, By);

   --  Merge another counter's state into this one.
   --  For each actor: takes the element-wise max of P and N.
   --  Actors present in Source but not in Target are added.
   procedure Merge (Target : in out PN_Counter;
                    Source : PN_Counter);

private

   type Actor_Entry is record
      Actor : Core.Replica_Id := 1;
      P     : Counter_Range := 0;
      N     : Counter_Range := 0;
   end record;

   type Actor_Array is array (Positive range <>) of Actor_Entry;

   type PN_Counter (Max_Actors : Positive) is record
      Entries : Actor_Array (1 .. Max_Actors);
      Count   : Natural := 0;
   end record;

   function Can_Increment (C : PN_Counter; By : Counter_Range := 1)
                             return Boolean is (True);

   function Can_Decrement (C : PN_Counter; By : Counter_Range := 1)
                             return Boolean is (True);

end Ada_CRDT.Pn_Counters;
