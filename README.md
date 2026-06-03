# CRDT

CRDT (Conflict-Free Replicated Data Types) library for Ada/SPARK.

## Install

### Alire Community Index

```bash
alr with crdt
```

Will work once added to the community index.

### Local Index

```bash
alr index --add git+https://codeberg.org/bladeacer/ada_crdt.git --name crdt
alr with crdt
```

Then, include `with "crdt";` in your `.gpr` file.

## Development

Clone and build locally:

```bash
git clone https://codeberg.org/bladeacer/ada_crdt.git
cd ada_crdt
make build
make run
```

## Core Types

### PN-Counter (Actor Map)

Per-replica increments/decrements. Fixed memory (3 replicas = 3 slots),
regardless of op count.

```ada
with CRDT.Pn_Counters;

A : CRDT.Pn_Counters.PN_Counter (Max_Actors => 5);
B : CRDT.Pn_Counters.PN_Counter (Max_Actors => 5);

CRDT.Pn_Counters.Increment (A, 5, Actor => 1);
CRDT.Pn_Counters.Increment (B, 10, Actor => 2);

CRDT.Pn_Counters.Merge (A, B);  -- value = 15
```

Package: `CRDT.Pn_Counters`

### LWW-Element-Set (Lamport Timestamps)

Last-Writer-Wins set using logical clocks (no wall-clock skew).

```ada
with CRDT.Lww_Element_Sets;
package Int_Set is new CRDT.Lww_Element_Sets (Integer, 100);

S1 : Int_Set.LWW_Element_Set (Capacity => 100);
S2 : Int_Set.LWW_Element_Set (Capacity => 100);

Int_Set.Add (S1, 42, (Stamp => 100, Node => 1));
Int_Set.Add (S2, 99, (Stamp => 50,  Node => 2));
Int_Set.Remove (S1, 42, (Stamp => 200, Node => 1));

Int_Set.Merge (S1, S2);
-- S1: contains 99 (added, never removed)
-- S1: contains 42 only if re-added with Stamp > 200
```

Package: `CRDT.Lww_Element_Sets` (generic over `Element_Type`, `Capacity`)

### RGA Sequence

Three backend engines, same API. See [API docs](docs/api-docs/index.md) for
full details.

```ada
with CRDT.Rga;
package Seq is new CRDT.Rga (Character, 100);
use Seq;

A : RGA (Capacity => 100);
B : RGA (Capacity => 100);

Insert (A, 1, (Replica => 1, Seq => 1), 'a');
Insert (A, 2, (Replica => 1, Seq => 2), 'b');
Insert (B, 1, (Replica => 2, Seq => 1), 'x');

Merge (A, B);  -- convergent state

-- Iterate
Pos : Cursor := First (A);
while Has_Element (Pos) loop
   Put (Element (A, Pos));
   Next (A, Pos);
end loop;
```

Package: `CRDT.Rga` (default engine) or `CRDT.Sequences.<Engine>`

### Engine Comparison

| Engine | Package | Design | Trade-off |
|--------|---------|--------|-----------|
| Yjs (default) | `CRDT.Rga` / `CRDT.Sequences.Yjs` | Chunk-based blocks, structural splitting | Fast bulk ops, larger tombstone overhead |
| Naive | `CRDT.Sequences.Naive` | Flat linked-list per element | Simple, O(n) lookups |
| Fugue | `CRDT.Sequences.Fugue` | BST tree with Depth ordering | Anti-interleaving, no GC rebalancing yet |

> It **helps to understand how suitable** each backend is for a given use case.

```ada
-- Switch engine by changing the with line
with CRDT.Sequences.Naive;
package S is new CRDT.Sequences.Naive (Character, 100);
```

### Sync Layer

State-based (CvRDT) with delta sync and HLC:

```ada
with CRDT.Sync.State_Based;

Config : Sync_Config := (Max_Replicas => 4, Delta_Sync => True, HLC_Node => 1);
Local  : Replica_State := Create (Config);
Remote : Replica_State := Create (Config);

Merge (Local, Remote);
```

Operation-based (CmRDT) with bounded op log and ack/GC:

```ada
with CRDT.Sync.Op_Based;

Log : Op_Log (Capacity => 1000);

Append (Log, (Kind => Op_Insert, Seq => 1, Node => 1, Position => 1));
Append (Log, (Kind => Op_Delete, Seq => 2, Node => 1, Del_Position => 1));

Acknowledge (Log, Up_To_Seq => 1);  -- mark delivered
Compact (Log);                       -- purge acknowledged ops
```

---

## Wrappers

Safety/constraint layers on top of core types.

### Thread-Safe (`CRDT.Protected`)

Protected-object wrappers (no manual locking):

```ada
with CRDT.Protected;

C : CRDT.Protected.Shared_PN_Counter (Max_Actors => 3);
C.Increment (5, Actor => 1);
C.Decrement (2, Actor => 1);
```

Also: `Shared_LWW` and `Shared_RGA` generics.

### Bounded (`CRDT.Bounded`)

Compile-time bounded, zero heap allocation:

```ada
with CRDT.Bounded;
package Bnd_RGA is new CRDT.Bounded.Bounded_RGA (Character, 100);
R : Bnd_RGA.Sequence;  -- fully bounded, heap-free
```

---

## Supporting Types

| Package | Role |
|---------|------|
| `CRDT.Core` | `Replica_Id`, `Lamport_Time`, `Protocol_Version`, VTime types |
| `CRDT.HLC` | Hybrid Logical Clock (physical + logical timestamp) |
| `CRDT.Rgas` | Multi-RGA container |

### HLC Example

```ada
with CRDT.HLC;

Clock : CRDT.HLC.Instance := CRDT.HLC.Create (Node => 1);
CRDT.HLC.Tick (Clock);   -- before sending
CRDT.HLC.Recv (Clock, Remote);  -- on receive, reconcile with remote time
```

---

## Wire Protocol

All serialized CRDT state begins with `Core.Protocol_Version` (currently `2`):

```
[Protocol_Version : Natural]  (LEB128-encoded)
[Payload]
```

### LEB128 Encoding

All `Natural` fields in the wire format use [LEB128](https://en.wikipedia.org/wiki/LEB128)
variable-length encoding (`CRDT.Core.LEB128`), producing 1-5 bytes per value
instead of the fixed 4-byte `Natural'Write`. Small values (common for clocks,
positions, and counts) use 1-2 bytes.

Fields encoded with LEB128:
- Protocol version (1 byte)
- Per-node element count in sets
- Sequence length and replica/sequence ID pairs
- Tombstone and strut counts in RGA chunks

This replaces the earlier fixed-width `Natural'Write` / `Natural'Read` format
(Protocol_Version 1). `Read_RGA` rejects mismatched versions, enabling safe
rolling upgrades.

---

## Building

| Command | Action |
|---------|--------|
| `make build` | Build library + tests |
| `make run` / `make test` | Run test suite (see [test results](test_result.md)) |
| `make prove` | SPARK proofs via `alr gnatprove` |
| `make demo` | Run Conway Game of Life Demo |
| `make doc` | Generate Markdown API docs (See [API docs](docs/api-docs/index.md) |
| `make clean` | Remove build artifacts |

Prerequisites: [Alire](https://alire.ada.dev) (manages GNAT automatically),
[Python 3](https://www.python.org/downloads/) for `make doc`.

---

## Demo

![Conway's Game of Life Demo](./demo.webp)

A real-time TUI simulation of Conway's Game of Life to stress-test and visually
prove the library's eventual consistency engine across three independent nodes.

### Running

```bash
make demo
```

### Features

Dual Backends (Toggle with M)
- Matrix Mode: Tracks live cells as discrete (Row, Col) elements in an
`LWW_Element_Set`. Uses Lamport timestamps to resolve split-brain conflicts with
absolute set consistency.
- `Yjs_RGA` Mode: Tracks grid rows as RGA Character sequences with chunk-splitting.
Serves as a sequence stress test by continuously sweeping, deleting, and
rebuilding text rows.

Simulation Boundaries & Performance
- Eventual Convergence: Replicas achieve strong eventual consistency eventually,
mimicking real-world gossip protocol behaviours.

- Complexity Evaluation: Tests the RGA merger's $O(n \cdot m)$ sequence loop,
utilizing linear array pointer scans and an internal O(n²) bubble-sort under
high-frequency load.

> tldr; yjs RGA is not a great CRDT type for Conway's Game of Life unlike `LWW_Element_Set`.
>
> As mentioned earlier, it **helps to understand how suitable** each backend is for a given use case.

- Zero-Heap Footprint: Relies on `CRDT.Bounded` types to completely eliminate
runtime allocation leaks during explosive cell birth/death cycles.

- Split-Brain Testing: Simulates random 0-5s per-node network freezes.
Disconnected nodes queue updates locally and auto-reconcile seamlessly upon healing.

Controls
- Terminal Safety: Built on native vt100 escape bindings with robust SIGINT
handling to guarantee full cursor and attribute restoration on exit.
- Keybinds: Q Quit, R Reset, P Global Pause, M Toggle Engine Type.

---

## SPARK Proof

Core packages (`CRDT.Pn_Counters`) SPARK-proven for run-time check elimination.
Generics (Sequences, LWW, RGA) are instantiation-dependent.

---

## Credits

Technology Stack:

- [SPARK / Ada 2012](https://www.adacore.com/languages/spark) (AdaCore): formal verification
- [Alire](https://alire.ada.dev): Ada/SPARK package manager
- [VT100](https://github.com/darkestkhan/vt100): Minimal Ada VT100 API library

Inspired by:

- PN-Counter: [Apache Cassandra](https://cassandra.apache.org) distributed
counters, [Riak](https://riak.com) CRDTs
- LWW-Element-Set: [Redis Enterprise](https://redis.io),
[SoundCloud Roshi](https://github.com/soundcloud/roshi); Lamport (1978)
- RGA: [Yjs / YATA](https://github.com/yjs/yjs) (Kevin Jahns): block CRDT text editing
- [Automerge](https://github.com/automerge/automerge)
(Martin Kleppmann et al.): JSON CRDT
- Fugue: tree-based interleaving prevention

## License

MIT.
