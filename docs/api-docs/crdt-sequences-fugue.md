# CRDT.Sequences.Fugue

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
Depth   : Natural := 0;
end record;
```

### type RGA

```ada
type RGA (Capacity : Positive) is private;
```

## Functions

### function "=" (Left : CRDT.Sequences.Fugue.RGA; Right : CRDT.Sequences.Fugue.RGA) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Left` | Left sequence operand. |
| `Right` | Right sequence operand. |

**Returns:** True if both sequences are identical.

### function Count (R : CRDT.Sequences.Fugue.RGA) return Standard.Natural

| Parameter | Description |
|-----------|-------------|
| `R` | The sequence to examine. |

**Returns:** Count of allocated nodes (includes tombstones).

### function Element (Container : CRDT.Sequences.Fugue.RGA; Position : CRDT.Sequences.Fugue.Cursor) return CRDT.Sequences.Fugue.Element_Type

| Parameter | Description |
|-----------|-------------|
| `Container` | The sequence container. |
| `Position` | Cursor to read from. |

**Returns:** Element at the cursor's position.

### function First (Container : CRDT.Sequences.Fugue.RGA) return CRDT.Sequences.Fugue.Cursor

| Parameter | Description |
|-----------|-------------|
| `Container` | The sequence container. |

**Returns:** Cursor positioned at first element.

### function Get (R : CRDT.Sequences.Fugue.RGA; Pos : Standard.Positive) return CRDT.Sequences.Fugue.Element_Type

| Parameter | Description |
|-----------|-------------|
| `Pos` | 1-based position. |
| `R` | The sequence. |

**Returns:** Element at that position.

### function Has_Element (Position : CRDT.Sequences.Fugue.Cursor) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Position` | Cursor to check. |

**Returns:** True if the cursor is within bounds.

### function Has_Element (Container : CRDT.Sequences.Fugue.RGA; Position : CRDT.Sequences.Fugue.Cursor) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Container` | The sequence container. |
| `Position` | Cursor to check. |

**Returns:** True if the cursor is within bounds.

### function Length (R : CRDT.Sequences.Fugue.RGA) return Standard.Natural

| Parameter | Description |
|-----------|-------------|
| `R` | The sequence to examine. |

**Returns:** Number of non-deleted elements.

### function Size (R : CRDT.Sequences.Fugue.RGA) return Standard.Natural

| Parameter | Description |
|-----------|-------------|
| `R` | The sequence to examine. |

**Returns:** Number of non-deleted elements.

## Procedures

### procedure Compact (R : CRDT.Sequences.Fugue.RGA)

| Parameter | Description |
|-----------|-------------|
| `R` | The sequence to compact. |

### procedure Delete (R : CRDT.Sequences.Fugue.RGA; Pos : Standard.Positive)

| Parameter | Description |
|-----------|-------------|
| `Pos` | 1-based position of element to delete. |
| `R` | The sequence to modify. |

### procedure Delete_Node (R : CRDT.Sequences.Fugue.RGA; Id : CRDT.Sequences.Fugue.Node_Id)

| Parameter | Description |
|-----------|-------------|
| `Id` | Node identifier of the item to delete. |
| `R` | The sequence to modify. |

### procedure Insert (R : CRDT.Sequences.Fugue.RGA; Pos : Standard.Positive; Id : CRDT.Sequences.Fugue.Node_Id; Value : CRDT.Sequences.Fugue.Element_Type)

| Parameter | Description |
|-----------|-------------|
| `Id` | Unique node identifier for this element. |
| `Pos` | 1-based insertion position. |
| `R` | The sequence to modify. |
| `Value` | Element to insert. |

### procedure Insert_Bulk (R : CRDT.Sequences.Fugue.RGA; Pos : Standard.Positive; Id : CRDT.Sequences.Fugue.Node_Id; Values : CRDT.Sequences.Fugue.Element_Array)

| Parameter | Description |
|-----------|-------------|
| `Id` | Unique node identifier (used for first element). |
| `Pos` | 1-based insertion position. |
| `R` | The sequence to modify. |
| `Values` | Array of elements to insert contiguously. |

### procedure Merge (Target : CRDT.Sequences.Fugue.RGA; Source : CRDT.Sequences.Fugue.RGA)

| Parameter | Description |
|-----------|-------------|
| `Source` | The sequence to merge from. |
| `Target` | The sequence to merge into. |

### procedure Next (Container : CRDT.Sequences.Fugue.RGA; Position : CRDT.Sequences.Fugue.Cursor)

| Parameter | Description |
|-----------|-------------|
| `Container` | The sequence container. |
| `Position` | Cursor to advance (modified in place). |

### procedure Read_RGA (Stream : Ada.Streams.Root_Stream_Type; Item : CRDT.Sequences.Fugue.RGA)

| Parameter | Description |
|-----------|-------------|
| `Item` | Deserialized RGA. |
| `Stream` | Input stream. |

### procedure Write_RGA (Stream : Ada.Streams.Root_Stream_Type; Item : CRDT.Sequences.Fugue.RGA)

| Parameter | Description |
|-----------|-------------|
| `Item` | RGA to serialize. |
| `Stream` | Output stream. |
