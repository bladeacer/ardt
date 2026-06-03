--  PN-Counter with per-replica actor map.
--  Tracks increments (P) and decrements (N) for each replica independently.
--  Fixed memory: 3 replicas = 3 slots regardless of millions of ops.
--  Value = sum(P) - sum(N).
with CRDT.Core;

package CRDT.Pn_Counters with
  SPARK_Mode
is

   --  Natural range for counter operations.
   subtype Counter_Range is Natural;

   --  Bounded PN-Counter with pre-allocated actor slots.
   --  @field Max_Actors  Maximum number of distinct replicas.
   type PN_Counter (Max_Actors : Positive) is private with
     Default_Initial_Condition;

   --  Current value of the counter (may be negative).
   --  @param C  The counter to query.
   --  @return   Net value (sum P minus sum N).
   function Value (C : PN_Counter) return Integer;

   pragma Warnings (Off, "unused variable");

   --  Check if increment is possible (always True for unbounded counters).
   --  @param C   The counter.
   --  @param By  Amount to increment.
   --  @return    Always True.
   function Can_Increment (C : PN_Counter; By : Counter_Range := 1)
                              return Boolean;

   --  Check if decrement is possible (always True for unbounded counters).
   --  @param C   The counter.
   --  @param By  Amount to decrement.
   --  @return    Always True.
   function Can_Decrement (C : PN_Counter; By : Counter_Range := 1)
                              return Boolean;
   pragma Warnings (On, "unused variable");

   --  Increment the counter by By for the given Actor (replica).
   --  Creates a new actor entry if this is the first operation from
   --  that replica.
   --  @param C      The counter to modify.
   --  @param By     Amount to increment (default 1).
   --  @param Actor  Replica performing the increment.
   procedure Increment (C     : in out PN_Counter;
                         By    : Counter_Range := 1;
                         Actor : Core.Replica_Id) with
     Pre => Can_Increment (C, By);

   --  Decrement the counter by By for the given Actor (replica).
   --  @param C      The counter to modify.
   --  @param By     Amount to decrement (default 1).
   --  @param Actor  Replica performing the decrement.
   procedure Decrement (C     : in out PN_Counter;
                         By    : Counter_Range := 1;
                         Actor : Core.Replica_Id) with
     Pre => Can_Decrement (C, By);

   --  Merge another counter's state into this one.
   --  For each actor: takes the element-wise max of P and N.
   --  Actors present in Source but not in Target are added.
   --  @param Target  Counter to merge into.
   --  @param Source  Counter to merge from.
   procedure Merge (Target : in out PN_Counter;
                     Source : PN_Counter);

private

   --  Per-actor P and N values.
   --  @field Actor  Replica identifier.
   --  @field P      Increment total from this actor.
   --  @field N      Decrement total from this actor.
   type Actor_Entry is record
      Actor : Core.Replica_Id := 1;
      P     : Counter_Range := 0;
      N     : Counter_Range := 0;
   end record;

   --  Array of actor entries.
   type Actor_Array is array (Positive range <>) of Actor_Entry;

   type PN_Counter (Max_Actors : Positive) is record
      Entries : Actor_Array (1 .. Max_Actors);
      Count   : Natural := 0;
   end record;

   function Can_Increment (C : PN_Counter; By : Counter_Range := 1)
                              return Boolean is (True);

   function Can_Decrement (C : PN_Counter; By : Counter_Range := 1)
                              return Boolean is (True);

end CRDT.Pn_Counters;
