# Zig-backed Lean JSON Parser Design

## Goal

Build a Lean library that exposes selected Zig standard library capabilities through a stable C ABI. The first module wraps Zig JSON parsing as a Lean-native API, using Zig as a high-performance host-side implementation while keeping Lean responsible for the public data model and future semantics.

## First Scope

The MVP covers JSON validation and tokenization:

- `validate : ByteArray -> Bool`
- `parseTokens : ByteArray -> Except JsonError (Array JsonToken)`

The MVP does not expose Zig allocator state, Zig slices, Zig structs, or a Zig-owned DOM tree to Lean.

## Architecture

```text
Lean API
  ↓ @[extern]
C ABI shim
  ↓
Zig static/shared library
  ↓
std.json
```

The C ABI layer is intentionally narrow. It accepts caller-owned byte buffers and returns status codes plus either required output size or a Zig-allocated output buffer that Lean releases through an exported free function.

## API Shape

Lean defines the public types:

```lean
inductive JsonTokenKind
  | objectStart
  | objectEnd
  | arrayStart
  | arrayEnd
  | string
  | number
  | bool
  | null

structure JsonToken where
  kind : JsonTokenKind
  offset : UInt64
  length : UInt64
```

Zig emits a compact token stream. For scalar tokens, `offset` and `length` point into the original input bytes. This avoids copying strings and numbers in the FFI layer.

## C ABI Boundary

The initial exported functions should be equivalent to:

```c
uint32_t ziglean_json_validate(const uint8_t* input, uint64_t input_len);

uint32_t ziglean_json_parse_tokens(
  const uint8_t* input,
  uint64_t input_len,
  ZigLeanJsonToken** out_tokens,
  uint64_t* out_len,
  ZigLeanJsonError* out_error
);

void ziglean_json_free_tokens(ZigLeanJsonToken* tokens, uint64_t len);
```

Return codes are stable integers. Error details are copied into a fixed-size ABI-safe struct containing code, offset, and optional message length.

## Error Handling

Lean maps Zig status codes into:

```lean
structure JsonError where
  code : UInt32
  offset : UInt64
  message : String
```

The first version should keep messages short and non-normative. Tests should assert on error codes and offsets, not full message text.

## Memory Ownership

Lean owns the input `ByteArray`. Zig owns the token buffer returned by `ziglean_json_parse_tokens`. Lean must call `ziglean_json_free_tokens` exactly once after copying tokens into Lean values.

No Zig pointer should escape into normal Lean APIs.

## Build Layout

Recommended package layout:

```text
Lakefile.lean
ZigLean/
  Json.lean
  FFI.lean
native/
  build.zig
  src/json.zig
  include/ziglean_json.h
test/
  JsonTest.lean
```

Lake should build the Zig library as a native artifact and link it into Lean tests/examples.

## Testing

The MVP test suite should cover:

- valid JSON objects, arrays, strings, numbers, booleans, and null
- malformed JSON with stable error offsets
- empty input and whitespace-only input
- Unicode escape and escaped string cases
- token offsets matching original input byte positions
- repeated parse/free cycles to catch ownership mistakes

## Non-goals

- No Zig DOM handle API in the MVP
- No schema validation in the MVP
- No direct exposure of Zig `std.json` internals
- No attempt to define on-chain semantics through Zig

## Extension Path

After the token stream is stable, add optional Lean-side helpers:

- convert token stream into a Lean JSON AST
- streaming parser interface
- JSON pointer/path query
- property tests comparing Lean parser behavior to Zig parser behavior
