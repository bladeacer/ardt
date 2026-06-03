# CRDT.Core.LEB128

## Procedures

### procedure Decode (Stream : Ada.Streams.Root_Stream_Type; Value : Standard.Natural)

| Parameter | Description |
|-----------|-------------|
| `Stream` | Source input stream. |
| `Value` | Decoded integer. |

### procedure Encode (Stream : Ada.Streams.Root_Stream_Type; Value : Standard.Natural)

| Parameter | Description |
|-----------|-------------|
| `Stream` | Target output stream. |
| `Value` | Integer to encode (0 .. Natural'Last). |
