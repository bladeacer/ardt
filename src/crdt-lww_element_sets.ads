--  Last-Writer-Wins Element Set using Lamport timestamps.
--  Stores (element, Lamport_Time) pairs for add and remove sets.
--  An element is present iff its add-timestamp exceeds its remove-timestamp.
--  Uses logical Lamport timestamps instead of wall clocks,
--  avoiding clock skew issues in distributed deployments.
--
--  @formal Element_Type  Type of elements to store in the set.
--  @formal Max_Set_Size  Maximum number of distinct elements.
--
--  Requirements traceability:
--  - HLR-LWW-CONTAINS: Element membership query
--  - HLR-LWW-ADD: Add element with Lamport timestamp
--  - HLR-LWW-REMOVE: Remove element with Lamport timestamp
--  - HLR-LWW-MERGE: Merge two LWW element sets
--  - HLR-LWW-SERIAL: V1/V2 wire format round-trip
with Ada.Streams;
with CRDT.Core;

generic
   type Element_Type is private;
   Max_Set_Size : Positive;
package CRDT.Lww_Element_Sets with
  SPARK_Mode
is

   Max_Capacity : constant Positive := Max_Set_Size;

   --  An element paired with its Lamport timestamp.
   --  @field Element  The stored value.
   --  @field Time     Lamport timestamp for LWW resolution.
   type Timestamp_Entry is record
      Element : Element_Type;
      Time    : Core.Lamport_Time;
   end record;

   --  Array of timestamped entries.
   type Timestamp_Array is array (Positive range <>) of Timestamp_Entry;

   --  Bounded LWW Element Set with pre-allocated capacity.
   type LWW_Element_Set (Capacity : Positive) is private;

   --  Return the number of add entries tracked.
   --  @param S  The set to query.
   --  @return   Add entry count, always <= Capacity.
   function Add_Count (S : LWW_Element_Set) return Natural with
     Post => Add_Count'Result <= S.Capacity;

   --  Return the number of remove entries tracked.
   --  @param S  The set to query.
   --  @return   Remove entry count, always <= Capacity.
   function Remove_Count (S : LWW_Element_Set) return Natural with
     Post => Remove_Count'Result <= S.Capacity;

   --  Check if an element is currently in the set.
   --  Returns True if the element's add timestamp
   --  exceeds its remove timestamp.
   --  @param S  The set to query.
   --  @param E  The element to look up.
   --  @return True if element is considered present.
   function Contains (S : LWW_Element_Set; E : Element_Type) return Boolean;

   --  Add an element with the given Lamport timestamp.
   --  @param S   The set to modify.
   --  @param E   Element to add.
   --  @param TS  Lamport timestamp for this add operation.
   procedure Add (S  : in out LWW_Element_Set;
                   E  : Element_Type;
                   TS : Core.Lamport_Time) with
     Post => Add_Count (S) <= S.Capacity;

   --  Remove an element with the given Lamport timestamp.
   --  @param S   The set to modify.
   --  @param E   Element to remove.
   --  @param TS  Lamport timestamp for this remove operation.
   procedure Remove (S  : in out LWW_Element_Set;
                      E  : Element_Type;
                      TS : Core.Lamport_Time) with
     Post => Add_Count (S) <= S.Capacity;

   --  Merge another set's add/remove entries into this set.
   --  For each entry, keeps the higher timestamp.
   --  @param Target  The set to merge into.
   --  @param Source  The set to merge from.
   procedure Merge (Target : in out LWW_Element_Set;
                     Source : LWW_Element_Set) with
     Post => Add_Count (Target) <= Target.Capacity;

    --  Remove all entries, resetting to empty state.
    --  @param S  The set to clear.
    procedure Clear (S : in out LWW_Element_Set) with
      Post => Add_Count (S) = 0 and then Remove_Count (S) = 0;

   --  Serialize set to stream (V2: LEB128-encoded sizes + canonical element stream).
   procedure Write_LWW_Element_Set
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Item   : LWW_Element_Set);

   --  Deserialize set from stream (auto-detects V1 vs V2).
   procedure Read_LWW_Element_Set
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Item   : out LWW_Element_Set);

   for LWW_Element_Set'Write use Write_LWW_Element_Set;
   for LWW_Element_Set'Read  use Read_LWW_Element_Set;

private

   type LWW_Element_Set (Capacity : Positive) is record
      Add_Array    : Timestamp_Array (1 .. Capacity);
      Add_Size     : Natural := 0;
      Remove_Array : Timestamp_Array (1 .. Capacity);
      Remove_Size  : Natural := 0;
   end record;

end CRDT.Lww_Element_Sets;
