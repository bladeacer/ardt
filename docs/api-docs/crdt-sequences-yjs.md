# CRDT.Sequences.Yjs

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
| `Left` | Left sequence operand. |
| `Right` | Right sequence operand. |

**Returns:** True if both sequences are identical.

### function Count (R : CRDT.Sequences.Yjs.RGA) return Standard.Natural

| Parameter | Description |
|-----------|-------------|
| `R` | The sequence to examine. |

**Returns:** Count of allocated nodes (includes tombstones).

### function Element (Container : CRDT.Sequences.Yjs.RGA; Position : CRDT.Sequences.Yjs.Cursor) return CRDT.Sequences.Yjs.Element_Type

| Parameter | Description |
|-----------|-------------|
| `Container` | The sequence container. |
| `Position` | Cursor to read from. |

**Returns:** Element at the cursor's position.

### function First (Container : CRDT.Sequences.Yjs.RGA) return CRDT.Sequences.Yjs.Cursor

| Parameter | Description |
|-----------|-------------|
| `Container` | The sequence container. |

**Returns:** Cursor positioned at first element.

### function Get (R : CRDT.Sequences.Yjs.RGA; Pos : Standard.Positive) return CRDT.Sequences.Yjs.Element_Type

| Parameter | Description |
|-----------|-------------|
| `Pos` | 1-based position. |
| `R` | The sequence. |

**Returns:** Element at that position.

### function Has_Element (Position : CRDT.Sequences.Yjs.Cursor) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Position` | Cursor to check. |

**Returns:** True if the cursor is within bounds.

### function Has_Element (Container : CRDT.Sequences.Yjs.RGA; Position : CRDT.Sequences.Yjs.Cursor) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Container` | The sequence container. |
| `Position` | Cursor to check. |

**Returns:** True if the cursor is within bounds.

### function Length (R : CRDT.Sequences.Yjs.RGA) return Standard.Natural

| Parameter | Description |
|-----------|-------------|
| `R` | The sequence to examine. |

**Returns:** Number of non-deleted elements.

### function Size (R : CRDT.Sequences.Yjs.RGA) return Standard.Natural

| Parameter | Description |
|-----------|-------------|
| `R` | The sequence to examine. |

**Returns:** Number of non-deleted elements.

## Procedures

### procedure Compact (R : CRDT.Sequences.Yjs.RGA)

| Parameter | Description |
|-----------|-------------|
| `R` | The sequence to compact. |

### procedure Compute_State_Vector (R : CRDT.Sequences.Yjs.RGA; SV : CRDT.Sequences.Yjs.Replica_Max_Seq_Array; Count : Standard.Natural)

| Parameter | Description |
|-----------|-------------|
| `Count` | Number of entries written to SV. |
| `R` | The sequence to analyze. |
| `SV` | Output array of per-replica max seq values. |

### procedure Delete (R : CRDT.Sequences.Yjs.RGA; Pos : Standard.Positive)

| Parameter | Description |
|-----------|-------------|
| `Pos` | 1-based position of element to delete. |
| `R` | The sequence to modify. |

### procedure Delete_Node (R : CRDT.Sequences.Yjs.RGA; Id : CRDT.Sequences.Yjs.Node_Id)

| Parameter | Description |
|-----------|-------------|
| `Id` | Node identifier of the item to delete. |
| `R` | The sequence to modify. |

### procedure Insert (R : CRDT.Sequences.Yjs.RGA; Pos : Standard.Positive; Id : CRDT.Sequences.Yjs.Node_Id; Value : CRDT.Sequences.Yjs.Element_Type)

| Parameter | Description |
|-----------|-------------|
| `Id` | Unique node identifier for this element. |
| `Pos` | 1-based insertion position. |
| `R` | The sequence to modify. |
| `Value` | Element to insert. |

### procedure Insert_Bulk (R : CRDT.Sequences.Yjs.RGA; Pos : Standard.Positive; Id : CRDT.Sequences.Yjs.Node_Id; Values : CRDT.Sequences.Yjs.Element_Array)

| Parameter | Description |
|-----------|-------------|
| `Id` | Unique node identifier (used for the first element). |
| `Pos` | 1-based insertion position. |
| `R` | The sequence to modify. |
| `Values` | Array of elements to insert contiguously. |

### procedure Merge (Target : CRDT.Sequences.Yjs.RGA; Source : CRDT.Sequences.Yjs.RGA)

| Parameter | Description |
|-----------|-------------|
| `Source` | The sequence to merge from. |
| `Target` | The sequence to merge into. |

### procedure Next (Container : CRDT.Sequences.Yjs.RGA; Position : CRDT.Sequences.Yjs.Cursor)

| Parameter | Description |
|-----------|-------------|
| `Container` | The sequence container. |
| `Position` | Cursor to advance (modified in place). |

### procedure Read_RGA (Stream : Ada.Streams.Root_Stream_Type; Item : CRDT.Sequences.Yjs.RGA)

| Parameter | Description |
|-----------|-------------|
| `Item` | Deserialized RGA. |
| `Stream` | Input stream. |

### procedure Sync_Delta (Target : CRDT.Sequences.Yjs.RGA; Source : CRDT.Sequences.Yjs.RGA; Remote_SV : CRDT.Sequences.Yjs.Replica_Max_Seq_Array; SV_Count : Standard.Natural)

| Parameter | Description |
|-----------|-------------|
| `Remote_SV` | State vector of the remote peer. |
| `SV_Count` | Number of entries in Remote_SV. |
| `Source` | The sequence to merge from. |
| `Target` | The sequence to merge into. |

### procedure Write_RGA (Stream : Ada.Streams.Root_Stream_Type; Item : CRDT.Sequences.Yjs.RGA)

| Parameter | Description |
|-----------|-------------|
| `Item` | RGA to serialize. |
| `Stream` | Output stream. |
