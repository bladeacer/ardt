--  Thread-safe protected-object wrappers for CRDT types.
--  Multiple tasks can concurrently mutate and query CRDT structures
--  without external locking. Built on Ada's native protected objects.
with CRDT.Core;
with CRDT.Pn_Counters;
with CRDT.Lww_Element_Sets;
with CRDT.Rga;

package CRDT.Protected is

   --  Thread-safe PN-Counter.
   --  @field Max_Actors  Maximum number of distinct replicas.
   protected type Shared_PN_Counter (Max_Actors : Positive) is

      --  Increment the counter for the given actor.
      --  @param By     Amount to increment.
      --  @param Actor  Replica performing the increment.
      procedure Increment (By    : Natural := 1;
                            Actor : Core.Replica_Id);

      --  Decrement the counter for the given actor.
      --  @param By     Amount to decrement.
      --  @param Actor  Replica performing the decrement.
      procedure Decrement (By    : Natural := 1;
                            Actor : Core.Replica_Id);

      --  Merge another counter's state into this one.
      --  @param Source  Counter to merge from.
      procedure Merge (Source : Pn_Counters.PN_Counter);

      --  Read the current value.
      --  @return  Net counter value.
      function Value return Integer;

      --  Take an atomic snapshot of the internal state.
      --  @return  Copy of the current counter state.
      function Snapshot return Pn_Counters.PN_Counter;
   private
      C : Pn_Counters.PN_Counter (Max_Actors);
   end Shared_PN_Counter;

   --  Thread-safe LWW-Element-Set.
   --  @formal Element_Type  Type of elements in the set.
   --  @formal Max_Set_Size  Maximum number of distinct elements.
   generic
      type Element_Type is private;
      Max_Set_Size : Positive;
   package Shared_LWW is
      package LWW_Pkg is new CRDT.Lww_Element_Sets
        (Element_Type, Max_Set_Size);

      --  Thread-safe LWW-element set.
      protected type Shared_Set (Capacity : Positive) is

         --  Add an element with the given timestamp.
         --  @param E   Element to add.
         --  @param TS  Lamport timestamp.
         procedure Add (E  : Element_Type;
                         TS : Core.Lamport_Time);

         --  Remove an element with the given timestamp.
         --  @param E   Element to remove.
         --  @param TS  Lamport timestamp.
         procedure Remove (E  : Element_Type;
                            TS : Core.Lamport_Time);

         --  Merge another set's state into this one.
         --  @param Source  Set to merge from.
         procedure Merge (Source : LWW_Pkg.LWW_Element_Set);

          --  Check if an element is present.
          --  @param E  Element to check.
          --  @return True if element is in the set.
         function Contains (E : Element_Type) return Boolean;

         --  Take an atomic snapshot.
         --  @return  Copy of the current set state.
         function Snapshot return LWW_Pkg.LWW_Element_Set;
      private
         S : LWW_Pkg.LWW_Element_Set (Capacity);
      end Shared_Set;
   end Shared_LWW;

   --  Thread-safe RGA (chunk-based Yjs engine).
   --  @formal Element_Type  Type of elements in the sequence.
   --  @formal Max_Size      Maximum number of internal nodes.
   --  @formal Max_Stride    Maximum block size for contiguous elements.
   generic
      type Element_Type is private;
      Max_Size   : Positive;
      Max_Stride : Positive := 64;
   package Shared_RGA is
      package RGA_Pkg is new CRDT.Rga
        (Element_Type, Max_Size, Max_Stride);

      --  Thread-safe mutable RGA sequence.
      protected type Shared_RGA_Obj (Capacity : Positive) is

         --  Insert element at position.
         --  @param Pos   1-based insertion position.
         --  @param Id    Unique node identifier.
         --  @param Value Element to insert.
         procedure Insert (Pos   : Positive;
                            Id    : RGA_Pkg.Node_Id;
                            Value : Element_Type);

         --  Insert multiple contiguous elements.
         --  @param Pos    1-based insertion position.
         --  @param Id     Unique node identifier for first element.
         --  @param Values  Array of elements to insert.
         procedure Insert_Bulk (Pos    : Positive;
                                 Id     : RGA_Pkg.Node_Id;
                                 Values : RGA_Pkg.Element_Array);

         --  Delete element at position.
         --  @param Pos  1-based position to delete.
         procedure Delete (Pos : Positive);

         --  Merge another sequence's state into this one.
         --  @param Source  Sequence to merge from.
         procedure Merge (Source : RGA_Pkg.RGA);

         --  Compact tombstones.
         procedure Compact;

         --  Get element at position.
         --  @param Pos  1-based position.
         --  @return Element at that position.
         function Get (Pos : Positive) return Element_Type;

         --  Current visible element count.
         --  @return Number of non-deleted elements.
         function Size return Natural;

         --  Take an atomic snapshot.
         --  @return  Copy of the current sequence state.
         function Snapshot return RGA_Pkg.RGA;
      private
         R : RGA_Pkg.RGA (Capacity);
      end Shared_RGA_Obj;
   end Shared_RGA;

end CRDT.Protected;
