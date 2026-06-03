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
| `Left` |  |
| `Right` |  |

### function Count (R : CRDT.Sequences.Fugue.RGA) return Standard.Natural

| Parameter | Description |
|-----------|-------------|
| `R` |  |

### function Element (Container : CRDT.Sequences.Fugue.RGA; Position : CRDT.Sequences.Fugue.Cursor) return CRDT.Sequences.Fugue.Element_Type

| Parameter | Description |
|-----------|-------------|
| `Container` |  |
| `Position` |  |

### function First (Container : CRDT.Sequences.Fugue.RGA) return CRDT.Sequences.Fugue.Cursor

| Parameter | Description |
|-----------|-------------|
| `Container` |  |

### function Get (R : CRDT.Sequences.Fugue.RGA; Pos : Standard.Positive) return CRDT.Sequences.Fugue.Element_Type

| Parameter | Description |
|-----------|-------------|
| `Pos` |  |
| `R` |  |

### function Has_Element (Position : CRDT.Sequences.Fugue.Cursor) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Position` |  |

### function Has_Element (Container : CRDT.Sequences.Fugue.RGA; Position : CRDT.Sequences.Fugue.Cursor) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Container` |  |
| `Position` |  |

### function Length (R : CRDT.Sequences.Fugue.RGA) return Standard.Natural

| Parameter | Description |
|-----------|-------------|
| `R` |  |

### function Size (R : CRDT.Sequences.Fugue.RGA) return Standard.Natural

| Parameter | Description |
|-----------|-------------|
| `R` |  |

## Procedures

### procedure Compact (R : CRDT.Sequences.Fugue.RGA)

| Parameter | Description |
|-----------|-------------|
| `R` |  |

### procedure Delete (R : CRDT.Sequences.Fugue.RGA; Pos : Standard.Positive)

| Parameter | Description |
|-----------|-------------|
| `Pos` |  |
| `R` |  |

### procedure Delete_Node (R : CRDT.Sequences.Fugue.RGA; Id : CRDT.Sequences.Fugue.Node_Id)

| Parameter | Description |
|-----------|-------------|
| `Id` |  |
| `R` |  |

### procedure Insert (R : CRDT.Sequences.Fugue.RGA; Pos : Standard.Positive; Id : CRDT.Sequences.Fugue.Node_Id; Value : CRDT.Sequences.Fugue.Element_Type)

| Parameter | Description |
|-----------|-------------|
| `Id` |  |
| `Pos` |  |
| `R` |  |
| `Value` |  |

### procedure Insert_Bulk (R : CRDT.Sequences.Fugue.RGA; Pos : Standard.Positive; Id : CRDT.Sequences.Fugue.Node_Id; Values : CRDT.Sequences.Fugue.Element_Array)

| Parameter | Description |
|-----------|-------------|
| `Id` |  |
| `Pos` |  |
| `R` |  |
| `Values` |  |

### procedure Merge (Target : CRDT.Sequences.Fugue.RGA; Source : CRDT.Sequences.Fugue.RGA)

| Parameter | Description |
|-----------|-------------|
| `Source` |  |
| `Target` |  |

### procedure Next (Container : CRDT.Sequences.Fugue.RGA; Position : CRDT.Sequences.Fugue.Cursor)

| Parameter | Description |
|-----------|-------------|
| `Container` |  |
| `Position` |  |

### procedure Read_RGA (Stream : Ada.Streams.Root_Stream_Type; Item : CRDT.Sequences.Fugue.RGA)

| Parameter | Description |
|-----------|-------------|
| `Item` |  |
| `Stream` |  |

### procedure Write_RGA (Stream : Ada.Streams.Root_Stream_Type; Item : CRDT.Sequences.Fugue.RGA)

| Parameter | Description |
|-----------|-------------|
| `Item` |  |
| `Stream` |  |
