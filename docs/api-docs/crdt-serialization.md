# CRDT.Serialization

CRDT: Conflict-Free Replicated Data Types for Ada/SPARK. Provides PN-Counters, LWW-Element-Sets, and Replicated Growable Arrays with modular sequence engines and thread-safe wrappers.

> **Note:** All items in this package are public.

## Types

### type Protocol_Kind

```ada
type Protocol_Kind is (Proto_V1, Proto_V2);
```

## Procedures

### procedure Read_Header (Stream : Ada.Streams.Root_Stream_Type; Kind : CRDT.Serialization.Protocol_Kind; Total : Standard.Natural; Count : Standard.Natural)

| Parameter | Description |
|-----------|-------------|
| `Count` |  |
| `Kind` |  |
| `Stream` |  |
| `Total` |  |

### procedure Read_Natural (Kind : CRDT.Serialization.Protocol_Kind; Stream : Ada.Streams.Root_Stream_Type; Value : Standard.Natural)

| Parameter | Description |
|-----------|-------------|
| `Kind` |  |
| `Stream` |  |
| `Value` |  |
