# Ada_CRDT

CRDT (Conflict-Free Replicated Data Types) library for Ada/SPARK.

**Status:** All 103 unit, property, integration, and chaos tests passing.

## Architecture

```
Ada_CRDT
├── Core              — Replica_Id, Lamport/HLC timestamps, VTime
├── HLC               — Hybrid Logical Clock
├── Pn_Counters       — Actor-map PN-Counter
├── Lww_Element_Sets  — Lamport-timestamped LWW Set
├── Sequences
│   ├── Yjs*          — Chunk-based splitting block engine
│   ├── Naive         — Per-element linked list (educational)
│   └── Fugue         — Tree-based anti-interleaving engine
├── Rga               — Default Yjs engine alias
├── Rgas              — Multi-RGA container
├── Sync
│   ├── State_Based   — CvRDT with delta sync + HLC
│   └── Op_Based      — CmRDT with operation log + GC
├── Protected         — Thread-safe protected-object wrappers
└── Bounded           — Compile-time bounded pre-allocated types
```

**(*) Default RGA engine.** Yjs-style splitting blocks with structural
splitting, state vectors, delta sync, and protocol-versioned serialization.

---

## PN-Counter (Actor Map)

Per-replica actor map tracking increments (P) and decrements (N)
independently per replica. Fixed memory: 3 replicas = 3 slots,
regardless of millions of increment operations.

**Package:** `Ada_CRDT.Pn_Counters`

```ada
with Ada_CRDT.Pn_Counters;

C : Ada_CRDT.Pn_Counters.PN_Counter (Max_Actors => 5);
Ada_CRDT.Pn_Counters.Increment (C, 5, Actor => 1);
Ada_CRDT.Pn_Counters.Decrement (C, 2, Actor => 1);
-- Value = 3
```

### LWW-Element-Set (Lamport Timestamps)

Last-Writer-Wins Element Set using Lamport timestamps (logical counter
+ node ID) instead of wall clocks — eliminating clock skew in
distributed systems. Generic over `Element_Type`.

**Package:** `Ada_CRDT.Lww_Element_Sets`

```ada
with Ada_CRDT.Lww_Element_Sets;
package Int_Set is new Ada_CRDT.Lww_Element_Sets (Integer, 100);

S : Int_Set.LWW_Element_Set (Capacity => 100);
Int_Set.Add (S, 42, (Stamp => 1000, Node => 1));
Int_Set.Add (S, 7,  (Stamp => 2000, Node => 1));
Int_Set.Remove (S, 42, (Stamp => 1500, Node => 1));
```

---

## Modular RGA Engines

Ada_CRDT provides three sequence engines selectable at compile time.
Each implements the same public API surface.

| Engine | Package | Design | Use Case |
|--------|---------|--------|----------|
| **Yjs** (default) | `Ada_CRDT.Sequences.Yjs` or `Ada_CRDT.Rga` | Chunk-based blocks (`Max_Stride`), structural splitting, arena allocation | Production CRDT text editing |
| **Naive** | `Ada_CRDT.Sequences.Naive` | Per-element nodes | Education, small sequences |
| **Fugue** | `Ada_CRDT.Sequences.Fugue` | BST tree identifiers with Depth | Preventing interleaving artifacts |

### Common API (all engines)

```ada
type Sequence is RGA (Capacity => ...);

function Count (R : Sequence) return Natural;
function Size  (R : Sequence) return Natural;
function Get   (R : Sequence; Pos : Positive) return Element_Type;

procedure Insert      (R : in out Sequence; Pos : Positive; Id : Node_Id; Value : Element_Type);
procedure Insert_Bulk (R : in out Sequence; Pos : Positive; Id : Node_Id; Values : Element_Array);
procedure Delete      (R : in out Sequence; Pos : Positive);
procedure Delete_Node (R : in out Sequence; Id : Node_Id);
procedure Merge       (Target : in out Sequence; Source : Sequence);
procedure Compact     (R : in out Sequence);

-- Serialization with protocol version header
procedure Write_RGA (Stream : access Root_Stream_Type'Class; Item : Sequence);
procedure Read_RGA  (Stream : access Root_Stream_Type'Class; Item : out Sequence);

-- State vector delta sync
procedure Compute_State_Vector (R : Sequence; SV : out Replica_Max_Seq_Array; Count : out Natural);
procedure Sync_Delta (Target : in out Sequence; Source : Sequence; Remote_SV : ...; SV_Count : Natural);
```

### Switching Engines

```ada
-- Yjs engine (default, chunk-based)
with Ada_CRDT.Rga;
package Seq is new Ada_CRDT.Rga (Character, 100);
R : Seq.RGA (Capacity => 100);

-- Naive engine (per-element)
with Ada_CRDT.Sequences.Naive;
package Seq_N is new Ada_CRDT.Sequences.Naive (Character, 100);
R2 : Seq_N.RGA (Capacity => 100);

-- Fugue engine (anti-interleaving tree)
with Ada_CRDT.Sequences.Fugue;
package Seq_F is new Ada_CRDT.Sequences.Fugue (Character, 100);
R3 : Seq_F.RGA (Capacity => 100);
```

---

## Iterator Support

All three engines implement Ada 2012 standard iterators:

### Cursor-Based Iteration

```ada
Pos : Seq.Cursor := Seq.Iterate (R);
while Seq.Has_Element (Pos) loop
   E := Seq.Constant_Ref (R, Pos).Element.all;
   -- process E
end loop;
```

### `for E of R` Loop (Ada 2012+)

```ada
for E of R loop
   -- E : Element_Type read-only
   Process (E);
end loop;
```

---

## Sync Layer

### State-Based CvRDT (`Ada_CRDT.Sync.State_Based`)

Replicas exchange full or delta-compressed state.
Fully idempotent — ideal for lossy networks (UDP, radio, mesh).

```ada
Config : Sync_Config := (Max_Replicas => 4, Delta_Sync => True, HLC_Node => 1);
Local  : Replica_State := Create (Config);
Remote : Replica_State := Create (Config);

Merge (Local, Remote);  -- merge remote state into local
```

### Operation-Based CmRDT (`Ada_CRDT.Sync.Op_Based`)

Replicas broadcast granular mutation events.
Minimum bandwidth — ideal for ordered channels (WebSocket, TCP).

```ada
Log : Op_Log (Capacity => 1000);

Append (Log, (Kind => Op_Insert, Seq => 1, Node => 1, Position => 1));
Append (Log, (Kind => Op_Delete, Seq => 2, Node => 1, Del_Position => 1));

Acknowledge (Log, Up_To_Seq => 1);  -- mark delivered
Compact (Log);                       -- purge acknowledged
```

---

## Thread-Safe Wrappers

Protected-object wrappers provide concurrent access without
manual locking:

```ada
with Ada_CRDT.Protected;

C : Ada_CRDT.Protected.Shared_PN_Counter (Max_Actors => 3);
C.Increment (5, Actor => 1);
C.Decrement (2, Actor => 1);
```

See `Ada_CRDT.Protected` for `Shared_LWW` and `Shared_RGA` generics.

---

## Wire Protocol

All serialized CRDT state begins with a `Protocol_Version` header:

```
[Protocol_Version : Natural]
[Payload]
```

The version constant is `Core.Protocol_Version` (currently `1`).
`Read_RGA` rejects payloads with mismatched version, enabling safe
rolling upgrades between library versions.

---

## Bounded Containers

All structures use pre-allocated arrays with compile-time capacities.
Zero heap allocation at runtime. Explicitly documented in
`Ada_CRDT.Bounded`.

```ada
with Ada_CRDT.Bounded;
package Bnd_RGA is new Ada_CRDT.Bounded.Bounded_RGA (Character, 100);
R : Bnd_RGA.Sequence;  -- fully bounded, heap-free
```

---

## Hybrid Logical Clock (HLC)

HLC combines physical wall-clock time with a logical counter,
preserving causality across clock-skewed nodes.

```ada
with Ada_CRDT.HLC;

Clock : Ada_CRDT.HLC.Instance := Ada_CRDT.HLC.Create (Node => 1);
Ada_CRDT.HLC.Tick (Clock);  -- before sending
Ada_CRDT.HLC.Recv (Clock, Remote);  -- on receive
```

---

## Building & Testing

| Command | Description |
|---------|-------------|
| `make` / `make help` | Show available targets |
| `make build` | Build library and tests |
| `make run` / `make test` | Build and run the test suite |
| `make prove` | Run SPARK proofs (`alr gnatprove`) |
| `make doc` | Generate HTML documentation (`gnatdoc`) |
| `make clean` | Remove build artifacts |

### Prerequisites

- **Alire** — https://alire.ada.dev
- **GNAT Ada compiler** (Alire manages automatically)

```bash
git clone https://codeberg.org/bladeacer/Ada_CRDT.git
cd Ada_CRDT
make build
make run
```

To use in your project:

```bash
cd /path/to/your-project
alr with --use /path/to/Ada_CRDT
```

---

## SPARK Proof

Core packages (`Ada_CRDT.Pn_Counters`) are fully SPARK-proven for
run-time check elimination. Generic packages (Sequences.*, LWW, RGA)
are skipped by gnatprove as generics depend on actual instantiation.

---

## Credits

### Technology

- **SPARK 2014 / Ada 2012** — Formal verification and safe systems
  programming language by AdaCore
- **Alire** — Ada/SPARK package manager and build system
- **GNAT** — GCC-based Ada compiler

### CRDT Research

- **PN-Counter** — Inspired by Apache Cassandra's distributed counters
  and Riak's CRDT implementation (actor map model)
- **LWW-Element-Set** — Redis Enterprise and SoundCloud Roshi;
  Lamport timestamp adaptation per Leslie Lamport's 1978 paper
- **Yjs** — YATA algorithm by Kevin Jahns for block-based CRDT text
  editing
- **Automerge** — JSON-based CRDT by Martin Kleppmann et al.
- **Fugue** — Tree-based CRDT for interleaving prevention

### Authors

- **Nicholas Wen** — Design and implementation

### Development

- LLMs were used to assist in the development process.

---

## License

MIT.
