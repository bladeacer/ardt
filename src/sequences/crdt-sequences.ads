--  Modular sequence engine hierarchy for CRDT.
--  Provides compile-time polymorphism between different RGA algorithms:
--    * Yjs     - Chunk-based splitting block engine (default)
--    * Naive   - Per-element linked list for educational use
--    * Fugue   - Tree-based identifiers to prevent interleaving
--
--  Each engine implements the same public API surface:
--    Insert, Insert_Bulk, Delete, Delete_Node, Merge
--    Get, Size, Count, Compact
--    Cursor-based and for-of iteration
--    Protocol-versioned serialization
--    State vector delta sync
package CRDT.Sequences is
end CRDT.Sequences;
