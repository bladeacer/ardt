# V1 → V2 Protocol Migration

_Applies to CRDT >= 1.4.0_

## Background

CRDT 1.0.0 and 1.1.0 serialised all integer values (header fields, node IDs,
lengths) using Ada's fixed 4-byte `Natural'Write` encoding (**V1 protocol**).
Starting with 1.2.0, the library switched to variable-length LEB128 encoding
(**V2 protocol**) for space efficiency — but V1 data could not yet be read.
Starting with 1.4.0, the read path supports both formats via auto-detection.

## Auto-Detection

The `Read_Header` procedure inspects the first 4 bytes of the stream:

```
Byte 1:  LEB128(2)  — protocol discriminator (always 0x02)
Byte 2:  LEB128(Total) — present in both V1 and V2
Byte 3:  LEB128(Count) — part of V2 encoding
Byte 4:
  - 0x00  → V1 (fixed 4-byte Natural'Read for all remaining fields)
  - ≠ 0x00 → V2 (LEB128 for all remaining fields)
```

After `Read_Header` returns, callers dispatch via `Read_Natural` which uses
the detected `Protocol_Kind` to select the correct decoder.

## What The User Sees

If you have existing code like this (works with both V1 and V2 data):

```ada
declare
   Stream : aliased Ada.Streams.Stream_IO.Stream_Access;
   Kind   : CRDT.Serialization.Protocol_Kind;
   Total  : Natural;
   Count  : Natural;
   Value  : Natural;
begin
   Ada.Streams.Stream_IO.Open (File, In_File, "data.bin");
   Stream := Ada.Streams.Stream_IO.Stream (File);

   --  Auto-detects V1 or V2 — no changes needed
   CRDT.Serialization.Read_Header (Stream.all'Access, Kind, Total, Count);

   for I in 1 .. Count loop
      CRDT.Serialization.Read_Natural (Kind, Stream.all'Access, Value);
      --  process Value ...
   end loop;

   Ada.Streams.Stream_IO.Close (File);
end;
```

Upgrading from any prior version to >= 1.4.0 requires **zero source-code changes**. The
same `Read_Header` / `Read_Natural` calls work unchanged.

## Writing V1 (Legacy Output)

If some peers are still on CRDT <= 1.1.0 and cannot read V2, use the legacy
writer for backward compatibility:

```ada
declare
   Stream : aliased Ada.Streams.Stream_IO.Stream_Access;
begin
   Ada.Streams.Stream_IO.Create (File, Out_File, "out.bin");
   Stream := Ada.Streams.Stream_IO.Stream (File);

   --  Write V1 header manually (binary discriminator + fixed-width fields)
   Natural'Write (Stream, 2);      -- Protocol_Version = 2 (as Natural)
   Natural'Write (Stream, Total);  -- Total
   Natural'Write (Stream, Count);  -- Count

   for I in 1 .. Count loop
      --  Legacy V1 field reader
      CRDT.Serialization.Legacy.Read_Natural_V1 (Stream.all'Access, Value);
   end loop;

   Ada.Streams.Stream_IO.Close (File);
end;
```

> **Recommendation**: Upgrade all peers to >= 1.4.0 to avoid maintaining V1
> write paths. The library's read side will continue to support V1 data
> indefinitely.

## Testing The Migration

The test suite includes a dedicated V1 migration test that constructs raw V1
wire-format data byte-by-byte and verifies that `Read_Header` + `Read_Natural`
produce identical results when reading V1 and V2 encodings of the same data.

Run it with:

```sh
make test
```

Look for `Migration: V1-V2 wire compat` in the output.
