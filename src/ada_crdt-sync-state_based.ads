--  State-Based (CvRDT) sync engine.
--  Replicas exchange full or delta-compressed state using
--  Hybrid Logical Clock (HLC) timestamps for causal ordering.
--
--  Network trait: Highly resilient to lossy/unstable topologies
--  (UDP, peer-to-peer mesh, radio datalinks) because state merges
--  are fully idempotent.
with Ada.Calendar;
with Ada_CRDT.Core;
with Ada_CRDT.HLC;

package Ada_CRDT.Sync.State_Based is

   --  Configuration for a state-based sync session.
   type Sync_Config is record
      Max_Replicas : Positive := 32;
      Delta_Sync   : Boolean := True;
      HLC_Node     : Core.Replica_Id;
   end record;

   --  State snapshot for a replica, tracking HLC clock and vector clock.
   type Replica_State (Max_Replicas : Positive) is private;

   --  Create initial state for a replica.
   function Create (Config : Sync_Config) return Replica_State;

   --  Merge received remote state into local state.
   procedure Merge (Local : in out Replica_State; Remote : Replica_State);

   --  Compute delta: how many items the remote is missing.
   function Compute_Delta (Local : Replica_State;
                           Remote_SV : Core.VTime) return Natural;

   --  Check if a state vector has advanced past a given Lamport timestamp.
   function Is_Ahead (SV : Core.VTime; TS : Core.Lamport_Time) return Boolean;

private

   type Replica_State (Max_Replicas : Positive) is record
      HLC_Clock : Ada_CRDT.HLC.Instance;
      SV        : Core.VTime (1 .. Max_Replicas);
   end record;

end Ada_CRDT.Sync.State_Based;
