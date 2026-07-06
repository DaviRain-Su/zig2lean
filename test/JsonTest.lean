import ZigLean
import ZigLean.Json.Decode

namespace JsonTest

open ZigLean
open ZigLean.Json

def bytes (s : String) : ByteArray :=
  s.toUTF8

def assertEq [BEq α] [ToString α] (name : String) (actual expected : α) : IO Unit := do
  if actual != expected then
    throw <| IO.userError s!"{name}: expected {expected}, got {actual}"

def pushU32LE (b : ByteArray) (n : UInt32) : ByteArray :=
  let b := b.push (UInt8.ofNat (n.toNat % 256))
  let b := b.push (UInt8.ofNat ((n.toNat / 256) % 256))
  let b := b.push (UInt8.ofNat ((n.toNat / 65536) % 256))
  b.push (UInt8.ofNat ((n.toNat / 16777216) % 256))

def pushU64LE (b : ByteArray) (n : UInt64) : ByteArray :=
  let rec loop (i factor : Nat) (acc : ByteArray) : ByteArray :=
    if _h : i < 8 then
      loop (i + 1) (factor * 256) (acc.push (UInt8.ofNat ((n.toNat / factor) % 256)))
    else
      acc
  loop 0 1 b

def sampleSuccess : ByteArray :=
  let b := ByteArray.empty
  let b := pushU32LE b 0
  let b := pushU32LE b 1
  let b := pushU64LE b 0
  let b := pushU32LE b 1
  let b := pushU32LE b 0
  let b := pushU64LE b 0
  pushU64LE b 1

def main : IO Unit := do
  assertEq "stub validate" (← Json.validate (bytes "{}")) true
  assertEq "valid object" (← Json.validate (bytes "{\"a\":1}")) true
  assertEq "valid array" (← Json.validate (bytes "[true,false,null]")) true
  assertEq "invalid trailing comma" (← Json.validate (bytes "{\"a\":1,}")) false
  assertEq "invalid empty input" (← Json.validate (bytes "")) false
  match decodeRawResult sampleSuccess with
  | Except.ok toks =>
      assertEq "token count" toks.size 1
      assertEq "token kind" toks[0]!.kind JsonTokenKind.objectStart
      assertEq "token offset" toks[0]!.offset 0
      assertEq "token length" toks[0]!.length 1
  | Except.error err =>
      throw <| IO.userError s!"expected success, got error code {err.code}"
  match ← Json.parseTokens (bytes "{\"a\":1,\"b\":[true,null]}") with
  | Except.error err =>
      throw <| IO.userError s!"parse success expected, got {err.code}"
  | Except.ok toks =>
      assertEq "parse token count" toks.size 9
      assertEq "first token" toks[0]!.kind JsonTokenKind.objectStart
      assertEq "key token" toks[1]!.kind JsonTokenKind.string
      assertEq "number token" toks[2]!.kind JsonTokenKind.number
      assertEq "array token" toks[4]!.kind JsonTokenKind.arrayStart
      assertEq "bool token" toks[5]!.kind JsonTokenKind.bool
      assertEq "null token" toks[6]!.kind JsonTokenKind.null
      assertEq "last token" toks[8]!.kind JsonTokenKind.objectEnd
  match ← Json.parseTokens (bytes "{\"a\":1,}") with
  | Except.ok toks =>
      throw <| IO.userError s!"parse error expected, got {toks.size} tokens"
  | Except.error err =>
      assertEq "error code" err.code 1
      assertEq "error offset" err.offset 7

  match ← Json.parseTokens (bytes "[\"a\\nb\"]") with
  | Except.error err =>
      throw <| IO.userError s!"escaped string parse expected, got {err.code}"
  | Except.ok toks =>
      assertEq "escaped string token count" toks.size 3
      assertEq "escaped string token kind" toks[1]!.kind JsonTokenKind.string
      assertEq "escaped string offset" toks[1]!.offset 2
      assertEq "escaped string raw length" toks[1]!.length 4

  match ← Json.parseTokens (bytes "[\"\\u263A\",\"\\uD83D\\uDE00\"]") with
  | Except.error err =>
      throw <| IO.userError s!"unicode string parse expected, got {err.code}"
  | Except.ok toks =>
      assertEq "unicode string token count" toks.size 4
      assertEq "unicode string first kind" toks[1]!.kind JsonTokenKind.string
      assertEq "unicode string first offset" toks[1]!.offset 2
      assertEq "unicode string first raw length" toks[1]!.length 6
      assertEq "unicode string second kind" toks[2]!.kind JsonTokenKind.string
      assertEq "unicode string second offset" toks[2]!.offset 11
      assertEq "unicode string second raw length" toks[2]!.length 12

  for _ in [0:100] do
    match ← Json.parseTokens (bytes "[1,2,3]") with
    | Except.error err =>
        throw <| IO.userError s!"repeat parse failed with {err.code}"
    | Except.ok toks =>
        assertEq "repeat token count" toks.size 5

end JsonTest

def main : IO Unit :=
  JsonTest.main
