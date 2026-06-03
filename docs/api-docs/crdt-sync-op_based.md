# CRDT.Sync.Op_Based

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
Seq     : Natural;
Node    : Core.Replica_Id;
case Kind is
when Op_Insert =>
Position : Positive;
when Op_Delete =>
Del_Position : Positive;
when Op_Increment | Op_Decrement =>
Amount    : Natural;
Actor     : Core.Replica_Id;
end case;
end record;
```

## Functions

### function Get (Log : CRDT.Sync.Op_Based.Op_Log; Index : Standard.Positive) return CRDT.Sync.Op_Based.Operation

| Parameter | Description |
|-----------|-------------|
| `Index` | 1-based index. |
| `Log` | Operation log to query. |

**Returns:** Operation at that index.

### function Size (Log : CRDT.Sync.Op_Based.Op_Log) return Standard.Natural

| Parameter | Description |
|-----------|-------------|
| `Log` | Operation log to query. |

**Returns:** Count of operations not yet acknowledged.

## Procedures

### procedure Acknowledge (Log : CRDT.Sync.Op_Based.Op_Log; Up_To_Seq : Standard.Natural)

| Parameter | Description |
|-----------|-------------|
| `Log` | Operation log to modify. |
| `Up_To_Seq` | Acknowledge all operations with Seq <= this. |

### procedure Append (Log : CRDT.Sync.Op_Based.Op_Log; Op : CRDT.Sync.Op_Based.Operation)

| Parameter | Description |
|-----------|-------------|
| `Log` | Operation log to append to. |
| `Op` | Operation to record. |

### procedure Compact (Log : CRDT.Sync.Op_Based.Op_Log)

| Parameter | Description |
|-----------|-------------|
| `Log` | Operation log to compact. |
