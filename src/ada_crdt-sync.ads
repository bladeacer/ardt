--  Sync layer interface for Ada_CRDT.
--  Provides two transport strategies:
--    * State_Based (CvRDT) — full state merge with delta compression
--    * Op_Based (CmRDT)    — granular operation broadcast with ack/GC
--
--  By separating the storage engine (Sequences.*) from the sync layer,
--  Ada's generic instantiation ensures unused code paths are optimized away,
--  maximizing performance and gnatprove compatibility.
with Ada_CRDT.Core;

package Ada_CRDT.Sync is

   --  State vector for tracking which per-replica updates a peer has seen.
   type State_Vector is array (Positive range <>) of Natural with
     Default_Component_Value => 0;

end Ada_CRDT.Sync;
