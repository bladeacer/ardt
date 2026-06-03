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
| `Local` |  |
| `Remote_SV` |  |

### function Create (Config : CRDT.Sync.State_Based.Sync_Config) return CRDT.Sync.State_Based.Replica_State

| Parameter | Description |
|-----------|-------------|
| `Config` |  |

### function Is_Ahead (SV : CRDT.Core.VTime; TS : CRDT.Core.Lamport_Time) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `SV` |  |
| `TS` |  |

## Procedures

### procedure Merge (Local : CRDT.Sync.State_Based.Replica_State; Remote : CRDT.Sync.State_Based.Replica_State)

| Parameter | Description |
|-----------|-------------|
| `Local` |  |
| `Remote` |  |
