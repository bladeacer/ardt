--  Bounded (pre-allocated) container wrappers.
--  All dynamic structures use fixed-size arrays specified at compile time.
--  Critical for mission-critical Ada/SPARK environments where
--  heap allocation is restricted to prevent fragmentation and OOM.
--
--  All types in CRDT natively use bounded storage; this package
--  provides convenient renamings and documentation.
with CRDT.Core;
with CRDT.Pn_Counters;
with CRDT.Lww_Element_Sets;
with CRDT.Rga;

package CRDT.Bounded is

   --  Bounded PN-Counter with a fixed maximum number of actors.
   subtype Bounded_PN_Counter is Pn_Counters.PN_Counter;

   --  Bounded LWW-Element-Set with a fixed capacity.
   --  @formal Element_Type  Type of elements in the set.
   --  @formal Max_Set_Size  Maximum number of distinct elements.
   generic
      type Element_Type is private;
      Max_Set_Size : Positive;
   package Bounded_LWW_Set is
      package LWW_Pkg is new CRDT.Lww_Element_Sets
        (Element_Type, Max_Set_Size);
      subtype Set is LWW_Pkg.LWW_Element_Set (Max_Set_Size);
   end Bounded_LWW_Set;

   --  Bounded RGA with fixed item capacity and stride.
   --  @formal Element_Type  Type of elements in the sequence.
   --  @formal Max_Items     Maximum number of internal nodes.
   --  @formal Max_Stride    Maximum block size for contiguous elements.
   --  @formal Max_Replicas  Maximum distinct replicas for delta sync.
   generic
      type Element_Type is private;
      Max_Items    : Positive;
      Max_Stride   : Positive := 64;
      Max_Replicas : Positive := 32;
   package Bounded_RGA is
      package RGA_Pkg is new CRDT.Rga
        (Element_Type, Max_Items, Max_Stride, Max_Replicas);
      subtype Sequence is RGA_Pkg.RGA (Max_Items);
   end Bounded_RGA;

end CRDT.Bounded;
