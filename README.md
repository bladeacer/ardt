# ardt

CRDT (Conflict-Free Replicated Data Types) library for Ada/SPARK.

## Provided Types

### PN-Counter

Positive-Negative Counter composed of two G-Counters (P for increments,
N for decrements).  Merge takes the element-wise maximum of P and N.
Value = P - N (can be negative).  Fully SPARK-proven.

**Package:** `Ardt.Pn_Counters`

### LWW-Element-Set

Last-Writer-Wins Element Set.  Stores (element, timestamp) pairs for
adds and removes.  An element is present iff its add-timestamp exceeds
its remove-timestamp.  Generic over `Element_Type`.

**Package:** `Ardt.Lww_Element_Sets`

### RGA

Replicated Growable Array — an ordered sequence with convergent merge.
Each element has a unique `Node_Id` (Replica + sequence number).
Deleted elements become tombstones.  Generic over `Element_Type`.

**Package:** `Ardt.Rga`

### RGAs

Container for managing multiple RGA instances.  Provides `Append` to
collect replicas and `Merge_All` to converge all into the first entry.

**Package:** `Ardt.Rgas`

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
git clone --depth 1 https://codeberg.org/bladeacer/ardt.git
cd ardt
make build     # or: alr build
make run       # or: alr run
```

To use `ardt` in your own Alire project:

```bash
cd /path/to/your-project
alr with --use /path/to/ardt
```

Then add `with Ardt.Pn_Counters;` (or the relevant package) to your Ada code.

## Usage

| CRDT Type | Package | Description |
|------|---------|-------------|
| **PN-Counter** | `Ardt.Pn_Counters` | Positive-Negative Counter — two G-Counters merged element-wise |
| **LWW-Element-Set** | `Ardt.Lww_Element_Sets` | Last-Writer-Wins Set — (element, timestamp) pairs for add/remove |
| **RGA** | `Ardt.Rga` | Replicated Growable Array — ordered sequence with merge |
| **RGAs** | `Ardt.Rgas` | Multi-RGA container with convergent merge |


### PN-Counter (state-based, no generics)

```ada
with Ardt.Pn_Counters;

procedure Example is
   C : Ardt.Pn_Counters.PN_Counter;
begin
   Ardt.Pn_Counters.Increment (C, 5);
   Ardt.Pn_Counters.Decrement (C, 2);
   -- Value = 3
end;
```

### LWW-Element-Set (generic)

```ada
with Ardt.Lww_Element_Sets;

procedure Example is
   package Int_Set is new Ardt.Lww_Element_Sets (Integer, 100);
   S : Int_Set.LWW_Element_Set (Capacity => 100);
begin
   Int_Set.Add (S, 42, 1000);
   Int_Set.Add (S, 7,  2000);

   if Int_Set.Contains (S, 42) then
      null;  -- true: add-ts (1000) > remove-ts (0, not present)
   end if;

   Int_Set.Remove (S, 42, 1500);
   -- now Contains (S, 42) = false: add-ts 1000 < remove-ts 1500
end;
```

### RGA (generic)

```ada
with Ardt.Rga;

procedure Example is
   package Char_RGA is new Ardt.Rga (Character, 50);
   R : Char_RGA.RGA (Capacity => 50);

   function Next_Id return Char_RGA.Node_Id is
     (Replica => 1, Seq => 1);  -- unique per insert
begin
   Char_RGA.Insert (R, 1, Next_Id, 'a');
   Char_RGA.Insert (R, 2, Next_Id, 'b');
   Char_RGA.Delete (R, 1);

   -- Get (R, 1) raises exception (deleted tombstone)
   -- Size (R)  = 2 (tombstone still counted)
end;
```

### RGAs (multi-RGA container)

```ada
with Ardt.Rgas;

procedure Example is
   package RGAs_Pkg is new Ardt.Rgas (Character, 50, 10);
   RS : RGAs_Pkg.RGAs (Count => 10);
   R1 : RGAs_Pkg.RGA_Entry;
   R2 : RGAs_Pkg.RGA_Entry;
begin
   RGAs_Pkg.RGA_Pkg.Insert (R1, 1, (1, 1), 'a');
   RGAs_Pkg.RGA_Pkg.Insert (R2, 1, (2, 1), 'b');

   RGAs_Pkg.Append (RS, R1);
   RGAs_Pkg.Append (RS, R2);
   RGAs_Pkg.Merge_All (RS);  -- merge all into first
end;
```

## Make Targets

| Command | Description |
|---------|-------------|
| `make` / `make help` | Show available targets |
| `make build` | Build library and tests |
| `make run` / `make test` | Build and run the test suite |
| `make prove` | Run SPARK proofs (`alr gnatprove`) |
| `make clean` | Remove build artifacts |

## SPARK Proof

The core packages (`Ardt.Pn_Counters`) are fully SPARK-proven for
run-time check elimination.  Generic packages (LWW, RGA, RGAs) are
skipped by `gnatprove` because generics are not analyzed by default
(they depend on the actual instantiation).

## LLM Usage

LLMs were used to assist in the development process.

## License

MIT.
