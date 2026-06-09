# CRDT.Protected.Shared_LWW

Thread-safe LWW-Element-Set.

> **Note:** All items in this package are public.

## Types

### type Shared_Set

```ada
      protected type Shared_Set (Capacity : Positive) is
```

> Thread-safe LWW-element set.

**Public Operations:**

#### procedure Add

```ada
         procedure Add (E  : Element_Type;
                         TS : Core.Lamport_Time);
```

Add an element with the given timestamp.

| Parameter | Description |
|-----------|-------------|
| `E` | Element to add. |
| `TS` | Lamport timestamp. |

#### procedure Remove

```ada
         procedure Remove (E  : Element_Type;
                            TS : Core.Lamport_Time);
```

Remove an element with the given timestamp.

| Parameter | Description |
|-----------|-------------|
| `E` | Element to remove. |
| `TS` | Lamport timestamp. |

#### procedure Merge

```ada
         procedure Merge (Source : LWW_Pkg.LWW_Element_Set);
```

Merge another set's state into this one.

| Parameter | Description |
|-----------|-------------|
| `Source` | Set to merge from. |

#### function Contains

```ada
         function Contains (E : Element_Type) return Boolean;
```

Check if an element is present.

| Parameter | Description |
|-----------|-------------|
| `E` | Element to check. |

**Returns:** True if element is in the set.

#### function Snapshot

```ada
         function Snapshot return LWW_Pkg.LWW_Element_Set;
```

Take an atomic snapshot.

**Returns:** Copy of the current set state.

**Private State:**

- `S : LWW_Pkg.LWW_Element_Set (Capacity);`
```ada
end Shared_Set;
```
