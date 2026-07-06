import ZigLean
import ZigLean.Json.Decode

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
