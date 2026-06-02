--  Thread-safe protected-object wrappers for Ada_CRDT types.
--  Multiple tasks can concurrently mutate and query CRDT structures
--  without external locking. Built on Ada's native protected objects.
with Ada_CRDT.Core;
with Ada_CRDT.Pn_Counters;
with Ada_CRDT.Lww_Element_Sets;
with Ada_CRDT.Rga;

package Ada_CRDT.Protected is

   --  Thread-safe PN-Counter.
   protected type Shared_PN_Counter (Max_Actors : Positive) is
      procedure Increment (By    : Natural := 1;
                           Actor : Core.Replica_Id);
      procedure Decrement (By    : Natural := 1;
                           Actor : Core.Replica_Id);
      procedure Merge (Source : Pn_Counters.PN_Counter);
      function Value return Integer;
      function Snapshot return Pn_Counters.PN_Counter;
   private
      C : Pn_Counters.PN_Counter (Max_Actors);
   end Shared_PN_Counter;

   --  Thread-safe LWW-Element-Set.
   generic
      type Element_Type is private;
      Max_Set_Size : Positive;
   package Shared_LWW is
      package LWW_Pkg is new Ada_CRDT.Lww_Element_Sets
        (Element_Type, Max_Set_Size);

      protected type Shared_Set (Capacity : Positive) is
         procedure Add (E  : Element_Type;
                        TS : Core.Lamport_Time);
         procedure Remove (E  : Element_Type;
                           TS : Core.Lamport_Time);
         procedure Merge (Source : LWW_Pkg.LWW_Element_Set);
         function Contains (E : Element_Type) return Boolean;
         function Snapshot return LWW_Pkg.LWW_Element_Set;
      private
         S : LWW_Pkg.LWW_Element_Set (Capacity);
      end Shared_Set;
   end Shared_LWW;

   --  Thread-safe RGA (chunk-based Yjs engine).
   generic
      type Element_Type is private;
      Max_Size   : Positive;
      Max_Stride : Positive := 64;
   package Shared_RGA is
      package RGA_Pkg is new Ada_CRDT.Rga
        (Element_Type, Max_Size, Max_Stride);

      protected type Shared_RGA_Obj (Capacity : Positive) is
         procedure Insert (Pos   : Positive;
                           Id    : RGA_Pkg.Node_Id;
                           Value : Element_Type);
         procedure Insert_Bulk (Pos    : Positive;
                                Id     : RGA_Pkg.Node_Id;
                                Values : RGA_Pkg.Element_Array);
         procedure Delete (Pos : Positive);
         procedure Merge (Source : RGA_Pkg.RGA);
         procedure Compact;
         function Get (Pos : Positive) return Element_Type;
         function Size return Natural;
         function Snapshot return RGA_Pkg.RGA;
      private
         R : RGA_Pkg.RGA (Capacity);
      end Shared_RGA_Obj;
   end Shared_RGA;

end Ada_CRDT.Protected;
