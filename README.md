# Ada_CRDT

CRDT (Conflict-Free Replicated Data Types) library for Ada/SPARK.

## Provided Types

### PN-Counter (Actor Map)

Positive-Negative Counter backed by a per-replica actor map.
Each replica tracks its own P (increment) and N (decrement) counts.
Merge takes the element-wise maximum of P and N for each actor.
Value = sum(P) - sum(N). Fixed memory: 3 nodes = 3 slots regardless
of millions of increments.

**Package:** `Ada_CRDT.Pn_Counters`

### LWW-Element-Set (Lamport Timestamps)

Last-Writer-Wins Element Set using Lamport timestamps (logical counter +
node ID) instead of wall clocks to avoid clock skew in distributed
systems. An element is present iff its add-timestamp exceeds its
remove-timestamp. Generic over `Element_Type`.

**Package:** `Ada_CRDT.Lww_Element_Sets`

### RGA (Chunk-Based)

Replicated Growable Array with chunk-based content storage.
Contiguous elements are stored in sized blocks (`Max_Stride`),
dramatically reducing allocation overhead vs. per-character nodes.
Each element has a unique `Node_Id` (Replica + sequence number).
Deleted elements become tombstones. Generic over `Element_Type`.

**Package:** `Ada_CRDT.Rga`

### RGAs

Container for managing multiple RGA instances. Provides `Append` to
collect replicas and `Merge_All` to converge all into the first entry.

**Package:** `Ada_CRDT.Rgas`

### Thread-Safe Wrappers

Protected-object wrappers for all CRDT types, providing out-of-the-box
concurrent access without manual locking.

**Package:** `Ada_CRDT.Protected`

### Bounded Containers

Pre-allocated bounded variants using compile-time capacities,
eliminating runtime heap allocation for mission-critical systems.

**Package:** `Ada_CRDT.Bounded`

### Hybrid Logical Clock (HLC)

HLC implementation combining physical wall-clock time with a logical
counter to preserve causality across clock-skewed nodes.

**Package:** `Ada_CRDT.HLC`

## Wire Protocol

All serialized CRDT state begins with a `Protocol_Version` header byte,
enabling forward/backward compatibility during rolling upgrades.

## Installation

### Prerequisites

- **Alire** (recommended) — install via your package manager or from
  https://alire.ada.dev
- **GNAT Ada compiler** (Alire manages this automatically).

### Installing Alire

```bash
# Debian/Ubuntu
sudo apt install alr

# Arch Linux
sudo pacman -S alr

# macOS (Homebrew)
brew install alr

# Or download from https://github.com/alire-project/alire/releases
```

Alire's first run prompts you to select a toolchain (compiler + gprbuild).
Accept the defaults; it downloads and manages them automatically.

### Getting the library

```bash
git clone --depth 1 https://codeberg.org/bladeacer/Ada_CRDT.git
cd Ada_CRDT
make build     # or: alr build
make run       # or: alr run
```

To use `Ada_CRDT` in your own Alire project:

```bash
cd /path/to/your-project
alr with --use /path/to/Ada_CRDT
```

Then add `with Ada_CRDT.Pn_Counters;` (or the relevant package) to your Ada code.

## Usage

| CRDT Type | Package | Description |
|------|---------|-------------|
| **PN-Counter** | `Ada_CRDT.Pn_Counters` | Per-replica actor map P/N counter |
| **LWW-Element-Set** | `Ada_CRDT.Lww_Element_Sets` | Lamport-timestamped LWW Set |
| **RGA** | `Ada_CRDT.Rga` | Chunk-based Replicated Growable Array |
| **RGAs** | `Ada_CRDT.Rgas` | Multi-RGA container with convergent merge |
| **Protected** | `Ada_CRDT.Protected` | Thread-safe protected-object wrappers |
| **Bounded** | `Ada_CRDT.Bounded` | Compile-time bounded pre-allocated types |
| **HLC** | `Ada_CRDT.HLC` | Hybrid Logical Clock for causal ordering |


### PN-Counter (Actor Map)

```ada
with Ada_CRDT.Pn_Counters;

procedure Example is
   C : Ada_CRDT.Pn_Counters.PN_Counter (Max_Actors => 5);
begin
   Ada_CRDT.Pn_Counters.Increment (C, 5, Actor => 1);
   Ada_CRDT.Pn_Counters.Decrement (C, 2, Actor => 1);
   -- Value = 3
end;
```

### LWW-Element-Set (Lamport Timestamps)

```ada
with Ada_CRDT.Lww_Element_Sets;

procedure Example is
   package Int_Set is new Ada_CRDT.Lww_Element_Sets (Integer, 100);
   S : Int_Set.LWW_Element_Set (Capacity => 100);
begin
   Int_Set.Add (S, 42, (Stamp => 1000, Node => 1));
   Int_Set.Add (S, 7,  (Stamp => 2000, Node => 1));
   Int_Set.Remove (S, 42, (Stamp => 1500, Node => 1));
end;
```

### RGA (Chunk-Based)

```ada
with Ada_CRDT.Rga;

procedure Example is
   package Char_RGA is new Ada_CRDT.Rga (Character, 50);
   R : Char_RGA.RGA (Capacity => 50);

   function Next_Id return Char_RGA.Node_Id is
     (Replica => 1, Seq => 1);
begin
   Char_RGA.Insert (R, 1, Next_Id, 'a');
   Char_RGA.Insert (R, 2, Next_Id, 'b');
   Char_RGA.Delete (R, 1);
end;
```

### Thread-Safe Protected Wrapper

```ada
with Ada_CRDT.Protected;

procedure Example is
   C : Ada_CRDT.Protected.Shared_PN_Counter (Max_Actors => 3);
begin
   C.Increment (5, 1);
   C.Decrement (2, 1);
end;
```

## SPARK Proof

The core packages (`Ada_CRDT.Pn_Counters`) are fully SPARK-proven for
run-time check elimination. Generic packages (LWW, RGA, RGAs) are
skipped by `gnatprove` because generics are not analyzed by default
(they depend on the actual instantiation).

## License

MIT.

## Credits

y.js, Ada.
