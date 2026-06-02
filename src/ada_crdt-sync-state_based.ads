with Ada.Calendar;
with Ada_CRDT.Core;
with Ada_CRDT.HLC;

package Ada_CRDT.Sync.State_Based is

   -- State-based (CvRDT) sync engine.
   -- Replicas exchange full or delta-compressed state,
   -- using HLC timestamps for causal ordering.

   -- Configuration for a state-based sync session
   type Sync_Config is record
      Max_Replicas : Positive := 32;
      Delta_Sync   : Boolean := True;
      HLC_Node     : Core.Replica_Id;
   end record;

   -- State snapshot for a replica
   type Replica_State (Max_Replicas : Positive) is private;

   -- Create initial state for a replica
   function Create (Config : Sync_Config) return Replica_State;

   -- Merge received remote state into local state
   procedure Merge (Local : in out Replica_State; Remote : Replica_State);

   -- Compute delta payload (only newer items) given remote's state vector
   -- Returns: number of items the remote is missing
   function Compute_Delta (Local : Replica_State;
                           Remote_SV : Core.VTime) return Natural;

   -- Check if state vector has advanced past given timestamp
   function Is_Ahead (SV : Core.VTime; TS : Core.Lamport_Time) return Boolean;

private

   type Replica_State (Max_Replicas : Positive) is record
      HLC_Clock : Ada_CRDT.HLC.Instance;
      SV        : Core.VTime (1 .. Max_Replicas);
   end record;

end Ada_CRDT.Sync.State_Based;
