# CRDT.Sync.Op_Based

CRDT: Conflict-Free Replicated Data Types for Ada/SPARK. Provides PN-Counters, LWW-Element-Sets, and Replicated Growable Arrays with modular sequence engines and thread-safe wrappers.

> **Note:** All items in this package are public.

## Types

### type Op_Kind

```ada
type Op_Kind is (Op_Insert, Op_Delete, Op_Increment, Op_Decrement);
```

### type Op_Log

```ada
type Op_Log (Capacity : Positive) is private;
```

### type Operation

```ada
type Operation (Kind : Op_Kind := Op_Insert) is record
```

| Field | Type |
|-------|------|
| `Seq` | Natural |
| `Node` | [`Core.Replica_Id`](crdt-core.md#type-replica_id) |

**Variants:**

- `when Op_Insert =>`

  ```ada
  Position : Positive
  ```

- `when Op_Delete =>`

  ```ada
  Del_Position : Positive
  ```

- `when Op_Increment | Op_Decrement =>`

  ```ada
  Amount : Natural
  ```

  ```ada
  Actor : [`Core.Replica_Id`](crdt-core.md#type-replica_id)
  ```


```ada
end record;
```

## Functions

### function Get (Log : CRDT.Sync.Op_Based.Op_Log; Index : Standard.Positive) return CRDT.Sync.Op_Based.Operation

| Parameter | Description |
|-----------|-------------|
| `Index` |  |
| `Log` |  |

### function Log_Count (Log : CRDT.Sync.Op_Based.Op_Log) return Standard.Natural

| Parameter | Description |
|-----------|-------------|
| `Log` |  |

### function Log_GC (Log : CRDT.Sync.Op_Based.Op_Log) return Standard.Natural

| Parameter | Description |
|-----------|-------------|
| `Log` |  |

### function Size (Log : CRDT.Sync.Op_Based.Op_Log) return Standard.Natural

| Parameter | Description |
|-----------|-------------|
| `Log` |  |

## Procedures

### procedure Acknowledge (Log : CRDT.Sync.Op_Based.Op_Log; Up_To_Seq : Standard.Natural)

| Parameter | Description |
|-----------|-------------|
| `Log` |  |
| `Up_To_Seq` |  |

### procedure Append (Log : CRDT.Sync.Op_Based.Op_Log; Op : CRDT.Sync.Op_Based.Operation)

| Parameter | Description |
|-----------|-------------|
| `Log` |  |
| `Op` |  |

### procedure Compact (Log : CRDT.Sync.Op_Based.Op_Log)

| Parameter | Description |
|-----------|-------------|
| `Log` |  |
