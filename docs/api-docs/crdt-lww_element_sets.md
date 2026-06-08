# CRDT.Lww_Element_Sets

Last-Writer-Wins Element Set using Lamport timestamps. Stores (element, Lamport_Time) pairs for add and remove sets. An element is present iff its add-timestamp exceeds its remove-timestamp. Uses logical Lamport timestamps instead of wall clocks, avoiding clock skew issues in distributed deployments. Requirements traceability: - HLR-LWW-CONTAINS: Element membership query - HLR-LWW-ADD: Add element with Lamport timestamp - HLR-LWW-REMOVE: Remove element with Lamport timestamp - HLR-LWW-MERGE: Merge two LWW element sets - HLR-LWW-SERIAL: V1/V2 wire format round-trip

> **Note:** 12 public item(s) shown below; 1 private internal item(s) are in the `private` section.

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

### function Add_Count (S : CRDT.Lww_Element_Sets.LWW_Element_Set) return Standard.Natural `[Post]`

| Parameter | Description |
|-----------|-------------|
| `S` | The set to query. |

**Returns:** Add entry count, always <= Capacity.

### function Contains (S : CRDT.Lww_Element_Sets.LWW_Element_Set; E : CRDT.Lww_Element_Sets.Element_Type) return Standard.Boolean

| Parameter | Description |
|-----------|-------------|
| `E` | The element to look up. |
| `S` | The set to query. |

**Returns:** True if element is considered present.

### function Remove_Count (S : CRDT.Lww_Element_Sets.LWW_Element_Set) return Standard.Natural `[Post]`

| Parameter | Description |
|-----------|-------------|
| `S` | The set to query. |

**Returns:** Remove entry count, always <= Capacity.

## Procedures

### procedure Add (S : CRDT.Lww_Element_Sets.LWW_Element_Set; E : CRDT.Lww_Element_Sets.Element_Type; TS : CRDT.Core.Lamport_Time) `[Post]`

| Parameter | Description |
|-----------|-------------|
| `E` | Element to add. |
| `S` | The set to modify. |
| `TS` | Lamport timestamp for this add operation. |

### procedure Clear (S : CRDT.Lww_Element_Sets.LWW_Element_Set) `[Post]`

| Parameter | Description |
|-----------|-------------|
| `S` | The set to clear. |

### procedure Merge (Target : CRDT.Lww_Element_Sets.LWW_Element_Set; Source : CRDT.Lww_Element_Sets.LWW_Element_Set) `[Post]`

| Parameter | Description |
|-----------|-------------|
| `Source` | The set to merge from. |
| `Target` | The set to merge into. |

### procedure Read_LWW_Element_Set (Stream : Ada.Streams.Root_Stream_Type; Item : CRDT.Lww_Element_Sets.LWW_Element_Set)

| Parameter | Description |
|-----------|-------------|
| `Item` |  |
| `Stream` |  |

### procedure Remove (S : CRDT.Lww_Element_Sets.LWW_Element_Set; E : CRDT.Lww_Element_Sets.Element_Type; TS : CRDT.Core.Lamport_Time) `[Post]`

| Parameter | Description |
|-----------|-------------|
| `E` | Element to remove. |
| `S` | The set to modify. |
| `TS` | Lamport timestamp for this remove operation. |

### procedure Write_LWW_Element_Set (Stream : Ada.Streams.Root_Stream_Type; Item : CRDT.Lww_Element_Sets.LWW_Element_Set)

| Parameter | Description |
|-----------|-------------|
| `Item` |  |
| `Stream` |  |

---

## Private Section

- **type** `LWW_Element_Set`
