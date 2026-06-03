# CRDT.Sequences.Naive

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

### type RGA

```ada
type RGA (Capacity : Positive) is private;
```

## Functions

### function "=" (Left : CRDT.Sequences.Naive.RGA; Right : CRDT.Sequences.Naive.RGA) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Left` |  |
| `Right` |  |

### function Count (R : CRDT.Sequences.Naive.RGA) return Standard.Natural

| Parameter | Description |
|-----------|-------------|
| `R` |  |

### function Element (Container : CRDT.Sequences.Naive.RGA; Position : CRDT.Sequences.Naive.Cursor) return CRDT.Sequences.Naive.Element_Type

| Parameter | Description |
|-----------|-------------|
| `Container` |  |
| `Position` |  |

### function First (Container : CRDT.Sequences.Naive.RGA) return CRDT.Sequences.Naive.Cursor

| Parameter | Description |
|-----------|-------------|
| `Container` |  |

### function Get (R : CRDT.Sequences.Naive.RGA; Pos : Standard.Positive) return CRDT.Sequences.Naive.Element_Type

| Parameter | Description |
|-----------|-------------|
| `Pos` |  |
| `R` |  |

### function Has_Element (Position : CRDT.Sequences.Naive.Cursor) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Position` |  |

### function Has_Element (Container : CRDT.Sequences.Naive.RGA; Position : CRDT.Sequences.Naive.Cursor) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Container` |  |
| `Position` |  |

### function Length (R : CRDT.Sequences.Naive.RGA) return Standard.Natural

| Parameter | Description |
|-----------|-------------|
| `R` |  |

### function Size (R : CRDT.Sequences.Naive.RGA) return Standard.Natural

| Parameter | Description |
|-----------|-------------|
| `R` |  |

## Procedures

### procedure Compact (R : CRDT.Sequences.Naive.RGA)

| Parameter | Description |
|-----------|-------------|
| `R` |  |

### procedure Delete (R : CRDT.Sequences.Naive.RGA; Pos : Standard.Positive)

| Parameter | Description |
|-----------|-------------|
| `Pos` |  |
| `R` |  |

### procedure Delete_Node (R : CRDT.Sequences.Naive.RGA; Id : CRDT.Sequences.Naive.Node_Id)

| Parameter | Description |
|-----------|-------------|
| `Id` |  |
| `R` |  |

### procedure Insert (R : CRDT.Sequences.Naive.RGA; Pos : Standard.Positive; Id : CRDT.Sequences.Naive.Node_Id; Value : CRDT.Sequences.Naive.Element_Type)

| Parameter | Description |
|-----------|-------------|
| `Id` |  |
| `Pos` |  |
| `R` |  |
| `Value` |  |

### procedure Insert_Bulk (R : CRDT.Sequences.Naive.RGA; Pos : Standard.Positive; Id : CRDT.Sequences.Naive.Node_Id; Values : CRDT.Sequences.Naive.Element_Array)

| Parameter | Description |
|-----------|-------------|
| `Id` |  |
| `Pos` |  |
| `R` |  |
| `Values` |  |

### procedure Merge (Target : CRDT.Sequences.Naive.RGA; Source : CRDT.Sequences.Naive.RGA)

| Parameter | Description |
|-----------|-------------|
| `Source` |  |
| `Target` |  |

### procedure Next (Container : CRDT.Sequences.Naive.RGA; Position : CRDT.Sequences.Naive.Cursor)

| Parameter | Description |
|-----------|-------------|
| `Container` |  |
| `Position` |  |

### procedure Read_RGA (Stream : Ada.Streams.Root_Stream_Type; Item : CRDT.Sequences.Naive.RGA)

| Parameter | Description |
|-----------|-------------|
| `Item` |  |
| `Stream` |  |

### procedure Write_RGA (Stream : Ada.Streams.Root_Stream_Type; Item : CRDT.Sequences.Naive.RGA)

| Parameter | Description |
|-----------|-------------|
| `Item` |  |
| `Stream` |  |
