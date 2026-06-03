# CRDT.Rgas

## Types

### type RGA_Array

```ada
type RGA_Array is array (Positive range <>) of RGA_Entry;
```

### type RGA_Entry

```ada
subtype RGA_Entry is RGA_Pkg.RGA (Max_RGA_Size);
```

### type RGAs

```ada
type RGAs (Count : Positive) is private;
```

## Functions

### function Get (RS : CRDT.Rgas.RGAs; Index : Standard.Positive) return CRDT.Rgas.RGA_Entry

| Parameter | Description |
|-----------|-------------|
| `Index` |  |
| `RS` |  |

### function Size (RS : CRDT.Rgas.RGAs) return Standard.Natural

| Parameter | Description |
|-----------|-------------|
| `RS` |  |

## Procedures

### procedure Append (RS : CRDT.Rgas.RGAs; R : CRDT.Rgas.RGA_Entry)

| Parameter | Description |
|-----------|-------------|
| `R` |  |
| `RS` |  |

### procedure Merge_All (RS : CRDT.Rgas.RGAs)

| Parameter | Description |
|-----------|-------------|
| `RS` |  |
