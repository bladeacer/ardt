--  State-Based (CvRDT) sync engine.
--  Replicas exchange full or delta-compressed state using
--  Hybrid Logical Clock (HLC) timestamps for causal ordering.
--
--  Network trait: Highly resilient to lossy/unstable topologies
--  (UDP, peer-to-peer mesh, radio datalinks) because state merges
--  are fully idempotent.
--
--  Requirements traceability:
--  - HLR-SYNC-STATE: State-based sync with vector clocks
--  - HLR-SYNC-DELTA: Delta computation for partial state exchange
with Ada.Calendar;
with CRDT.Core;
with CRDT.HLC;

package CRDT.Sync.State_Based with
  SPARK_Mode
is

   --  Configuration for a state-based sync session.
   --  @field Max_Replicas  Upper bound on distinct replicas.
   --  @field Delta_Sync    Enable delta compression.
   --  @field HLC_Node      Replica ID for the HLC instance.
   type Sync_Config is record
      Max_Replicas : Positive := 32;
      Delta_Sync   : Boolean := True;
      HLC_Node     : Core.Replica_Id;
   end record;

   --  State snapshot for a replica, tracking HLC clock and vector clock.
   type Replica_State (Max_Replicas : Positive) is private;

   --  Create initial state for a replica.
   --  @param Config  Sync configuration.
   --  @return  Freshly initialized replica state.
   function Create (Config : Sync_Config) return Replica_State;

   --  Merge received remote state into local state.
   --  @param Local   Local state to update.
   --  @param Remote  Remote state to merge from.
   procedure Merge (Local : in out Replica_State; Remote : Replica_State);

   --  Compute delta: how many items the remote is missing.
   --  @param Local      Local replica state.
   --  @param Remote_SV  Remote state vector.
   --  @return  Count of items the remote peer is behind.
   function Compute_Delta (Local : Replica_State;
                            Remote_SV : Core.VTime) return Natural with
     Post => Compute_Delta'Result = 0;

   --  Check if a state vector has advanced past a given Lamport timestamp.
   --  @param SV  State vector to check.
   --  @param TS  Lamport timestamp to compare against.
   --  @return  True if the SV has entry at or past TS.
   function Is_Ahead (SV : Core.VTime; TS : Core.Lamport_Time) return Boolean with
     Post => (if TS.Stamp = 0 then not Is_Ahead'Result
              else (Is_Ahead'Result =
                      (for some I in SV'Range => Natural (SV (I)) >= TS.Stamp)));

private

   type Replica_State (Max_Replicas : Positive) is record
      HLC_Clock : CRDT.HLC.Instance;
      SV        : Core.VTime (1 .. Max_Replicas);
   end record;

end CRDT.Sync.State_Based;
