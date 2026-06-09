--  Sync layer interface for CRDT.
--  Provides two transport strategies:
--    * State_Based (CvRDT): full state merge with delta compression
--    * Op_Based (CmRDT)   : granular operation broadcast with ack/GC
--
--  By separating the storage engine (Sequences.*) from the sync layer,
--  Ada's generic instantiation ensures unused code paths are optimized away,
--  maximizing performance and gnatprove compatibility.
with CRDT.Core;

package CRDT.Sync with
  SPARK_Mode
is

   --  State vector for tracking which per-replica updates a peer has seen.
   --  Indexed by replica slot; each element is the highest sequence number
   --  received from that replica.
   type State_Vector is array (Positive range <>) of Natural with
     Default_Component_Value => 0;

end CRDT.Sync;
