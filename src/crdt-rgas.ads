--  Container for managing multiple RGA instances.
--  Provides Append to collect replicas and Merge_All to converge
--  all into the first entry.
--
--  @formal Element_Type   Type of elements stored in each RGA.
--  @formal Max_RGA_Size   Capacity of each individual RGA.
--  @formal Max_RGA_Count  Maximum number of RGA instances.
--  @formal Max_Stride     Block size for chunk-based storage.
--  @formal Max_Replicas   Maximum distinct replicas for delta sync.
with CRDT.Rga;

generic
   type Element_Type is private;
   Max_RGA_Size   : Positive;
   Max_RGA_Count  : Positive;
   Max_Stride     : Positive := 64;
   Max_Replicas   : Positive := 32;
package CRDT.Rgas with
  SPARK_Mode
is

   package RGA_Pkg is new CRDT.Rga
     (Element_Type,
      Max_Items     => Max_RGA_Size,
      Max_Stride    => Max_Stride,
      Max_Replicas  => Max_Replicas);

   subtype RGA_Entry is RGA_Pkg.RGA (Max_RGA_Size);

   type RGA_Array is array (Positive range <>) of RGA_Entry;

   --  Bounded collection of RGA instances.
   type RGAs (Count : Positive) is private;

   --  Number of RGA entries currently stored.
   --  @return Current count of appended entries.
   function Size (RS : RGAs) return Natural;

   --  Get the RGA at the given index (1-based).
   --  @param RS     The collection.
   --  @param Index  1-based index.
   --  @return RGA entry at that index.
   function Get (RS : RGAs; Index : Positive) return RGA_Entry;

   --  Append an RGA to the collection.
   --  @param RS  The collection to append to.
   --  @param R   RGA entry to append.
   procedure Append (RS : in out RGAs; R : RGA_Entry);

   --  Merge all RGAs into the first entry (index 1).
   --  @param RS  The collection whose entries are merged.
   procedure Merge_All (RS : in out RGAs);

private

   type RGAs (Count : Positive) is record
      A    : RGA_Array (1 .. Count);
      Sz   : Natural := 0;
   end record;

end CRDT.Rgas;
