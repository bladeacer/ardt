# CRDT.Sequences.Yjs

CRDT: Conflict-Free Replicated Data Types for Ada/SPARK. Provides PN-Counters, LWW-Element-Sets, and Replicated Growable Arrays with modular sequence engines and thread-safe wrappers.

> **Note:** All items in this package are public.

## Types

### type Cursor

```ada
type Cursor is private;
```

### type Element_Array

```ada
type Element_Array is array (Positive range <>) of Element_Type;
```

### type Node_Id

```ada
type Node_Id is record
Replica : Core.Replica_Id;
Seq     : Natural;
end record;
```

### type Replica_Max_Seq

```ada
type Replica_Max_Seq is record
Replica : Core.Replica_Id;
Max_Seq : Natural;
end record;
```

### type Replica_Max_Seq_Array

```ada
type Replica_Max_Seq_Array is array (Positive range <>) of Replica_Max_Seq;
```

### type RGA

```ada
type RGA (Item_Capacity : Positive) is private;
```

## Functions

### function "=" (Left : CRDT.Sequences.Yjs.RGA; Right : CRDT.Sequences.Yjs.RGA) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Left` |  |
| `Right` |  |

### function Count (R : CRDT.Sequences.Yjs.RGA) return Standard.Natural

| Parameter | Description |
|-----------|-------------|
| `R` |  |

### function Element (Container : CRDT.Sequences.Yjs.RGA; Position : CRDT.Sequences.Yjs.Cursor) return CRDT.Sequences.Yjs.Element_Type

| Parameter | Description |
|-----------|-------------|
| `Container` |  |
| `Position` |  |

### function First (Container : CRDT.Sequences.Yjs.RGA) return CRDT.Sequences.Yjs.Cursor

| Parameter | Description |
|-----------|-------------|
| `Container` |  |

### function Get (R : CRDT.Sequences.Yjs.RGA; Pos : Standard.Positive) return CRDT.Sequences.Yjs.Element_Type

| Parameter | Description |
|-----------|-------------|
| `Pos` |  |
| `R` |  |

### function Has_Element (Position : CRDT.Sequences.Yjs.Cursor) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Position` |  |

### function Has_Element (Container : CRDT.Sequences.Yjs.RGA; Position : CRDT.Sequences.Yjs.Cursor) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Container` |  |
| `Position` |  |

### function Length (R : CRDT.Sequences.Yjs.RGA) return Standard.Natural

| Parameter | Description |
|-----------|-------------|
| `R` |  |

### function Size (R : CRDT.Sequences.Yjs.RGA) return Standard.Natural

| Parameter | Description |
|-----------|-------------|
| `R` |  |

## Procedures

### procedure Compact (R : CRDT.Sequences.Yjs.RGA)

| Parameter | Description |
|-----------|-------------|
| `R` |  |

### procedure Compute_State_Vector (R : CRDT.Sequences.Yjs.RGA; SV : CRDT.Sequences.Yjs.Replica_Max_Seq_Array; Count : Standard.Natural)

| Parameter | Description |
|-----------|-------------|
| `Count` |  |
| `R` |  |
| `SV` |  |

### procedure Delete (R : CRDT.Sequences.Yjs.RGA; Pos : Standard.Positive)

| Parameter | Description |
|-----------|-------------|
| `Pos` |  |
| `R` |  |

### procedure Delete_Node (R : CRDT.Sequences.Yjs.RGA; Id : CRDT.Sequences.Yjs.Node_Id)

| Parameter | Description |
|-----------|-------------|
| `Id` |  |
| `R` |  |

### procedure Insert (R : CRDT.Sequences.Yjs.RGA; Pos : Standard.Positive; Id : CRDT.Sequences.Yjs.Node_Id; Value : CRDT.Sequences.Yjs.Element_Type)

| Parameter | Description |
|-----------|-------------|
| `Id` |  |
| `Pos` |  |
| `R` |  |
| `Value` |  |

### procedure Insert_Bulk (R : CRDT.Sequences.Yjs.RGA; Pos : Standard.Positive; Id : CRDT.Sequences.Yjs.Node_Id; Values : CRDT.Sequences.Yjs.Element_Array)

| Parameter | Description |
|-----------|-------------|
| `Id` |  |
| `Pos` |  |
| `R` |  |
| `Values` |  |

### procedure Merge (Target : CRDT.Sequences.Yjs.RGA; Source : CRDT.Sequences.Yjs.RGA)

| Parameter | Description |
|-----------|-------------|
| `Source` |  |
| `Target` |  |

### procedure Next (Container : CRDT.Sequences.Yjs.RGA; Position : CRDT.Sequences.Yjs.Cursor)

| Parameter | Description |
|-----------|-------------|
| `Container` |  |
| `Position` |  |

### procedure Read_RGA (Stream : Ada.Streams.Root_Stream_Type; Item : CRDT.Sequences.Yjs.RGA)

| Parameter | Description |
|-----------|-------------|
| `Item` |  |
| `Stream` |  |

### procedure Sync_Delta (Target : CRDT.Sequences.Yjs.RGA; Source : CRDT.Sequences.Yjs.RGA; Remote_SV : CRDT.Sequences.Yjs.Replica_Max_Seq_Array; SV_Count : Standard.Natural)

| Parameter | Description |
|-----------|-------------|
| `Remote_SV` |  |
| `SV_Count` |  |
| `Source` |  |
| `Target` |  |

### procedure Write_RGA (Stream : Ada.Streams.Root_Stream_Type; Item : CRDT.Sequences.Yjs.RGA)

| Parameter | Description |
|-----------|-------------|
| `Item` |  |
| `Stream` |  |
