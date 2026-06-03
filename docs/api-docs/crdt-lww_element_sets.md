# CRDT.Lww_Element_Sets

## Types

### type LWW_Element_Set

```ada
type LWW_Element_Set (Capacity : Positive) is private;
```

### type Timestamp_Array

```ada
type Timestamp_Array is array (Positive range <>) of Timestamp_Entry;
```

### type Timestamp_Entry

```ada
type Timestamp_Entry is record
Element : Element_Type;
Time    : Core.Lamport_Time;
end record;
```

## Functions

### function Contains (S : CRDT.Lww_Element_Sets.LWW_Element_Set; E : CRDT.Lww_Element_Sets.Element_Type) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `E` |  |
| `S` |  |

## Procedures

### procedure Add (S : CRDT.Lww_Element_Sets.LWW_Element_Set; E : CRDT.Lww_Element_Sets.Element_Type; TS : CRDT.Core.Lamport_Time)

| Parameter | Description |
|-----------|-------------|
| `E` |  |
| `S` |  |
| `TS` |  |

### procedure Clear (S : CRDT.Lww_Element_Sets.LWW_Element_Set)

| Parameter | Description |
|-----------|-------------|
| `S` |  |

### procedure Merge (Target : CRDT.Lww_Element_Sets.LWW_Element_Set; Source : CRDT.Lww_Element_Sets.LWW_Element_Set)

| Parameter | Description |
|-----------|-------------|
| `Source` |  |
| `Target` |  |

### procedure Remove (S : CRDT.Lww_Element_Sets.LWW_Element_Set; E : CRDT.Lww_Element_Sets.Element_Type; TS : CRDT.Core.Lamport_Time)

| Parameter | Description |
|-----------|-------------|
| `E` |  |
| `S` |  |
| `TS` |  |
