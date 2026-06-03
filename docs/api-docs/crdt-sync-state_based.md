# CRDT.Sync.State_Based

## Types

### type Replica_State

```ada
type Replica_State (Max_Replicas : Positive) is private;
```

### type Sync_Config

```ada
type Sync_Config is record
Max_Replicas : Positive := 32;
Delta_Sync   : Boolean := True;
HLC_Node     : Core.Replica_Id;
end record;
```

## Functions

### function Compute_Delta (Local : CRDT.Sync.State_Based.Replica_State; Remote_SV : CRDT.Core.VTime) return Standard.Natural

| Parameter | Description |
|-----------|-------------|
| `Local` | Local replica state. |
| `Remote_SV` | Remote state vector. |

**Returns:** Count of items the remote peer is behind.

### function Create (Config : CRDT.Sync.State_Based.Sync_Config) return CRDT.Sync.State_Based.Replica_State

| Parameter | Description |
|-----------|-------------|
| `Config` | Sync configuration. |

**Returns:** Freshly initialized replica state.

### function Is_Ahead (SV : CRDT.Core.VTime; TS : CRDT.Core.Lamport_Time) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `SV` | State vector to check. |
| `TS` | Lamport timestamp to compare against. |

**Returns:** True if the SV has entry at or past TS.

## Procedures

### procedure Merge (Local : CRDT.Sync.State_Based.Replica_State; Remote : CRDT.Sync.State_Based.Replica_State)

| Parameter | Description |
|-----------|-------------|
| `Local` | Local state to update. |
| `Remote` | Remote state to merge from. |
