# CRDT.Rga

## Types

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

### function "=" (Left : CRDT.Rga.RGA; Right : CRDT.Rga.RGA) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `Left` |  |
| `Right` |  |

### function Count (R : CRDT.Rga.RGA) return Standard.Natural

| Parameter | Description |
|-----------|-------------|
| `R` |  |

### function Get (R : CRDT.Rga.RGA; Pos : Standard.Positive) return CRDT.Rga.Element_Type

| Parameter | Description |
|-----------|-------------|
| `Pos` |  |
| `R` |  |

### function Length (R : CRDT.Rga.RGA) return Standard.Natural

| Parameter | Description |
|-----------|-------------|
| `R` |  |

### function Size (R : CRDT.Rga.RGA) return Standard.Natural

| Parameter | Description |
|-----------|-------------|
| `R` |  |

## Procedures

### procedure Compact (R : CRDT.Rga.RGA)

| Parameter | Description |
|-----------|-------------|
| `R` |  |

### procedure Compute_State_Vector (R : CRDT.Rga.RGA; SV : CRDT.Rga.Replica_Max_Seq_Array; Count : Standard.Natural)

| Parameter | Description |
|-----------|-------------|
| `Count` |  |
| `R` |  |
| `SV` |  |

### procedure Delete (R : CRDT.Rga.RGA; Pos : Standard.Positive)

| Parameter | Description |
|-----------|-------------|
| `Pos` |  |
| `R` |  |

### procedure Delete_Node (R : CRDT.Rga.RGA; Id : CRDT.Rga.Node_Id)

| Parameter | Description |
|-----------|-------------|
| `Id` |  |
| `R` |  |

### procedure Insert (R : CRDT.Rga.RGA; Pos : Standard.Positive; Id : CRDT.Rga.Node_Id; Value : CRDT.Rga.Element_Type)

| Parameter | Description |
|-----------|-------------|
| `Id` |  |
| `Pos` |  |
| `R` |  |
| `Value` |  |

### procedure Insert_Bulk (R : CRDT.Rga.RGA; Pos : Standard.Positive; Id : CRDT.Rga.Node_Id; Values : CRDT.Rga.Element_Array)

| Parameter | Description |
|-----------|-------------|
| `Id` |  |
| `Pos` |  |
| `R` |  |
| `Values` |  |

### procedure Merge (Target : CRDT.Rga.RGA; Source : CRDT.Rga.RGA)

| Parameter | Description |
|-----------|-------------|
| `Source` |  |
| `Target` |  |

### procedure Read_RGA (Stream : Ada.Streams.Root_Stream_Type; Item : CRDT.Rga.RGA)

| Parameter | Description |
|-----------|-------------|
| `Item` |  |
| `Stream` |  |

### procedure Sync_Delta (Target : CRDT.Rga.RGA; Source : CRDT.Rga.RGA; Remote_SV : CRDT.Rga.Replica_Max_Seq_Array; SV_Count : Standard.Natural)

| Parameter | Description |
|-----------|-------------|
| `Remote_SV` |  |
| `SV_Count` |  |
| `Source` |  |
| `Target` |  |

### procedure Write_RGA (Stream : Ada.Streams.Root_Stream_Type; Item : CRDT.Rga.RGA)

| Parameter | Description |
|-----------|-------------|
| `Item` |  |
| `Stream` |  |
