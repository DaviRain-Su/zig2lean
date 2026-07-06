import ZigLean

namespace CodecTest

open ZigLean.Codec

def bytes (s : String) : ByteArray :=
  s.toUTF8

def assertEq [BEq α] [ToString α] (name : String) (actual expected : α) : IO Unit := do
  if actual != expected then
    throw <| IO.userError s!"{name}: expected {expected}, got {actual}"

def assertBytes (name : String) (actual expected : ByteArray) : IO Unit := do
  if actual != expected then
    throw <| IO.userError s!"{name}: byte arrays differ; expected size {expected.size}, got {actual.size}"

def sampleBytes : ByteArray :=
  (ByteArray.empty.push 0x00).push 0xff |>.push 0x10

def expectDecodeOk (name : String) (actual : Except CodecError ByteArray) (expected : ByteArray) : IO Unit := do
  match actual with
  | Except.ok bytes => assertBytes name bytes expected
  | Except.error err => throw <| IO.userError s!"{name}: expected decode success, got code {err.code}"

def expectDecodeError (name : String) (actual : Except CodecError ByteArray) (expectedCode : UInt32) (expectedOffset : UInt64) : IO Unit := do
  match actual with
  | Except.ok bytes => throw <| IO.userError s!"{name}: expected decode error, got {bytes.size} bytes"
  | Except.error err =>
    assertEq s!"{name} code" err.code expectedCode
    assertEq s!"{name} offset" err.offset expectedOffset

def main : IO Unit := do
  assertEq "hex encode empty" (← hexEncodeLower ByteArray.empty) ""
  assertEq "hex encode sample" (← hexEncodeLower sampleBytes) "00ff10"
  expectDecodeOk "hex decode lowercase" (← hexDecode "00ff10") sampleBytes
  expectDecodeOk "hex decode uppercase" (← hexDecode "00FF10") sampleBytes
  expectDecodeError "hex decode odd length" (← hexDecode "abc") 1 0
  expectDecodeError "hex decode invalid char" (← hexDecode "00xz") 2 0

  assertEq "base64 encode empty" (← base64Encode ByteArray.empty) ""
  assertEq "base64 encode hello" (← base64Encode (bytes "hello")) "aGVsbG8="
  expectDecodeOk "base64 decode empty" (← base64Decode "") ByteArray.empty
  expectDecodeOk "base64 decode hello" (← base64Decode "aGVsbG8=") (bytes "hello")
  expectDecodeError "base64 invalid padding" (← base64Decode "aGVsbG8") 2 0

  assertEq "base64url encode hello query" (← base64UrlEncode (bytes "hello?world")) "aGVsbG8_d29ybGQ"
  expectDecodeOk "base64url decode hello query" (← base64UrlDecode "aGVsbG8_d29ybGQ") (bytes "hello?world")

  for _ in [0:100] do
    assertEq "repeat hex encode" (← hexEncodeLower sampleBytes) "00ff10"
    expectDecodeOk "repeat base64 decode" (← base64Decode "aGVsbG8=") (bytes "hello")

end CodecTest

def main : IO Unit :=
  CodecTest.main
