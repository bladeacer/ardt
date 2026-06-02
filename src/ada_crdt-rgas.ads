--  Container for managing multiple RGA instances.
--  Provides Append to collect replicas and Merge_All to converge
--  all into the first entry.
with Ada_CRDT.Rga;

generic
   type Element_Type is private;
   Max_RGA_Size   : Positive;
   Max_RGA_Count  : Positive;
   Max_Stride     : Positive := 64;
   Max_Replicas   : Positive := 32;
package Ada_CRDT.Rgas with
  SPARK_Mode
is

   package RGA_Pkg is new Ada_CRDT.Rga
     (Element_Type,
      Max_Items     => Max_RGA_Size,
      Max_Stride    => Max_Stride,
      Max_Replicas  => Max_Replicas);

   subtype RGA_Entry is RGA_Pkg.RGA (Max_RGA_Size);

   type RGA_Array is array (Positive range <>) of RGA_Entry;

   type RGAs (Count : Positive) is private;

   --  Number of RGA entries currently stored.
   function Size (RS : RGAs) return Natural;

   --  Get the RGA at the given index (1-based).
   function Get (RS : RGAs; Index : Positive) return RGA_Entry;

   --  Append an RGA to the collection.
   procedure Append (RS : in out RGAs; R : RGA_Entry);

   --  Merge all RGAs into the first entry (index 1).
   procedure Merge_All (RS : in out RGAs);

private

   type RGAs (Count : Positive) is record
      A    : RGA_Array (1 .. Count);
      Sz   : Natural := 0;
   end record;

end Ada_CRDT.Rgas;
