# CRDT.Core.LEB128

LEB128 variable-length integer encoding for compact wire protocol. Small values (0-127) encode as a single byte instead of 4 (Natural'Write), dramatically reducing bandwidth for the many single-digit fields in CRDT serialization (protocol version, counts, lengths). Two interfaces: * Buffer-based (SPARK_Mode => On, provably safe) * Stream-based (SPARK_Mode => Off, for backward compat with Ada.Streams) Requirements traceability: - HLR-PROTO-LEB128: LEB128 encode/decode for variable-length integers

> **Note:** All items in this package are public.

## Types

### type Byte_Array

```ada
subtype Byte_Array is Stream_Element_Array;
```

## Procedures

### procedure Decode (Buffer : CRDT.Core.LEB128.Byte_Array; Index : Ada.Streams.Stream_Element_Offset; Value : Standard.Natural) `[SPARK]`

| Parameter | Description |
|-----------|-------------|
| `Buffer` |  |
| `Index` |  |
| `Value` | Decoded integer. |

### procedure Decode (Stream : Ada.Streams.Root_Stream_Type; Value : Standard.Natural) `[SPARK]`

| Parameter | Description |
|-----------|-------------|
| `Stream` | Source input stream. |
| `Value` | Decoded integer. |

### procedure Encode (Buffer : CRDT.Core.LEB128.Byte_Array; Index : Ada.Streams.Stream_Element_Offset; Value : Standard.Natural) `[SPARK]`

| Parameter | Description |
|-----------|-------------|
| `Buffer` |  |
| `Index` |  |
| `Value` | Integer to encode (0 .. Natural'Last). |

### procedure Encode (Stream : Ada.Streams.Root_Stream_Type; Value : Standard.Natural) `[SPARK]`

| Parameter | Description |
|-----------|-------------|
| `Stream` | Target output stream. |
| `Value` | Integer to encode (0 .. Natural'Last). |
