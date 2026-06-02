# ardt

CRDT (Conflict-Free Replicated Data Types) library for Ada/SPARK.

## Provided Types

| CRDT | Package | Description |
|------|---------|-------------|
| **PN-Counter** | `Ardt.Pn_Counters` | Positive-Negative Counter — two G-Counters merged element-wise |
| **LWW-Element-Set** | `Ardt.Lww_Element_Sets` | Last-Writer-Wins Set — (element, timestamp) pairs for add/remove |
| **RGA** | `Ardt.Rga` | Replicated Growable Array — ordered sequence with merge |
| **RGAs** | `Ardt.Rgas` | Multi-RGA container with convergent merge |

## Usage

```ada
with Ardt.Pn_Counters;
with Ardt.Lww_Element_Sets;
with Ardt.Rga;
with Ardt.Rgas;

procedure Example is
   -- PN-Counter (state-based, no generics needed)
   C : Ardt.Pn_Counters.PN_Counter;
begin
   Ardt.Pn_Counters.Increment (C, 5);
   Ardt.Pn_Counters.Decrement (C, 2);
   -- Value = 3
end Example;
```

### Generic Instantiations

LWW-Element-Set and RGA are generic:

```ada
-- LWW-Element-Set of Integer with max 100 entries
package Int_Set is new Ardt.Lww_Element_Sets (Integer, 100);
S : Int_Set.LWW_Element_Set (Capacity => 100);

Int_Set.Add (S, 42, Timestamp => 1000);
Int_Set.Remove (S, 42, Timestamp => 2000);
```

```ada
-- RGA of Character with max 50 nodes
package Char_RGA is new Ardt.Rga (Character, 50);
R : Char_RGA.RGA (Capacity => 50);

Char_RGA.Insert (R, 1, (Replica => 1, Seq => 1), 'a');
Char_RGA.Insert (R, 2, (Replica => 1, Seq => 2), 'b');
```

```ada
-- RGAs: container of multiple RGA instances
package RGAs_Pkg is new Ardt.Rgas (Character, 50, 10);
RS : RGAs_Pkg.RGAs (Count => 10);

RGAs_Pkg.Append (RS, R1);
RGAs_Pkg.Append (RS, R2);
RGAs_Pkg.Merge_All (RS);  -- merge all into first
```

## Installation

### Prerequisites

- **Alire** (recommended): install via your package manager or from
  https://alire.ada.dev — see below.
- **GNAT Ada compiler** (Alire will manage this automatically).

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

Alire's first run will prompt you to select a toolchain (compiler + gprbuild).
Accept the defaults; it downloads and manages them automatically.

### Getting the library

```bash
git clone --depth 1 https://codeberg.org/bladeacer/ardt.git
cd ardt
make build     # or: alr build
make run       # or: alr run
```

To use ardt in your own Alire project:

```bash
cd /path/to/your-project
alr with --use /path/to/ardt  # local path dependency
```

Then add `with Ardt.Pn_Counters;` (or the relevant package) to your Ada code.

## Make Targets

| Command | Description |
|---------|-------------|
| `make` or `make help` | Show available targets |
| `make build` | Build library and tests |
| `make run` or `make test` | Build and run the test suite |
| `make prove` | Run SPARK proofs (`alr gnatprove`) |
| `make clean` | Remove build artifacts |

## LLM Usage

LLMs were used to assist in the development process.

## License

MIT.
