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

def repeatByte (n : Nat) (b : UInt8) : ByteArray :=
  let rec loop (i : Nat) (acc : ByteArray) : ByteArray :=
    if _h : i < n then loop (i + 1) (acc.push b) else acc
  loop 0 ByteArray.empty

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

  assertEq "base58 encode empty" (← base58Encode ByteArray.empty) ""
  assertEq "base58 encode zero byte" (← base58Encode (ByteArray.empty.push 0x00)) "1"
  assertEq "base58 encode four zeros" (← base58Encode (repeatByte 4 0x00)) "1111"
  assertEq "base58 encode 0x61" (← base58Encode (ByteArray.empty.push 0x61)) "2g"
  assertEq "base58 encode sample" (← base58Encode sampleBytes) "1LQo"
  assertEq "base58 encode ff10" (← base58Encode ((ByteArray.empty.push 0xff).push 0x10)) "LQo"

  expectDecodeOk "base58 decode empty" (← base58Decode "") ByteArray.empty
  expectDecodeOk "base58 decode 1" (← base58Decode "1") (ByteArray.empty.push 0x00)
  expectDecodeOk "base58 decode 1111" (← base58Decode "1111") (repeatByte 4 0x00)
  expectDecodeOk "base58 decode 2g" (← base58Decode "2g") (ByteArray.empty.push 0x61)
  expectDecodeOk "base58 decode sample" (← base58Decode "1LQo") sampleBytes
  expectDecodeOk "base58 decode ff10" (← base58Decode "LQo") ((ByteArray.empty.push 0xff).push 0x10)
  expectDecodeError "base58 invalid char" (← base58Decode "2gI") 2 2
  expectDecodeError "base58 invalid zero char" (← base58Decode "20") 2 1

  assertEq "base32 encode empty" (← base32Encode ByteArray.empty) ""
  assertEq "base32 encode hello" (← base32Encode (bytes "hello")) "NBSWY3DP"
  expectDecodeOk "base32 decode empty" (← base32Decode "") ByteArray.empty
  expectDecodeOk "base32 decode hello" (← base32Decode "NBSWY3DP") (bytes "hello")
  expectDecodeError "base32 invalid char" (← base32Decode "NBSWY3D!") 2 7
  expectDecodeError "base32 invalid padding" (← base32Decode "NBSWY3D") 2 0

  for _ in [0:100] do
    assertEq "repeat hex encode" (← hexEncodeLower sampleBytes) "00ff10"
    expectDecodeOk "repeat base64 decode" (← base64Decode "aGVsbG8=") (bytes "hello")

end CodecTest

def main : IO Unit :=
  CodecTest.main
