# CRDT.Test_Support

CRDT: Conflict-Free Replicated Data Types for Ada/SPARK. Provides PN-Counters, LWW-Element-Sets, and Replicated Growable Arrays with modular sequence engines and thread-safe wrappers.

> **Note:** All items in this package are public.

## Types

### type Category_Array

```ada
type Category_Array is array (Positive range <>) of Category_Entry;
```

### type Category_Entry

```ada
type Category_Entry is record
Name : Ada.Strings.Unbounded.Unbounded_String;
Tag  : Ada.Strings.Unbounded.Unbounded_String;
R    : access Runner'Class;
end record;
```

### type Runner

```ada
type Runner is tagged limited private;
```

## Functions

### function Failed (R : CRDT.Test_Support.Runner) return Standard.Natural

| Parameter | Description |
|-----------|-------------|
| `R` |  |

### function Passed (R : CRDT.Test_Support.Runner) return Standard.Natural

| Parameter | Description |
|-----------|-------------|
| `R` |  |

## Procedures

### procedure Check (R : CRDT.Test_Support.Runner; Cond : Standard.Boolean; Msg : Standard.String)

| Parameter | Description |
|-----------|-------------|
| `Cond` |  |
| `Msg` |  |
| `R` |  |

### procedure Print_Summary_Table (To : Ada.Text_IO.File_Type; Cats : CRDT.Test_Support.Category_Array)

| Parameter | Description |
|-----------|-------------|
| `Cats` |  |
| `To` |  |
