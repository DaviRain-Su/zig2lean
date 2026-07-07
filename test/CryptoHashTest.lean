import ZigLean

namespace CryptoHashTest

open ZigLean.Crypto.Hash
open ZigLean.Crypto.Hash.Stream

def bytes (s : String) : ByteArray :=
  s.toUTF8

def assertEq [BEq α] [ToString α] (name : String) (actual expected : α) : IO Unit := do
  if actual != expected then
    throw <| IO.userError s!"{name}: expected {expected}, got {actual}"

def assertByteArrayEq (name : String) (actual expected : ByteArray) : IO Unit := do
  if actual != expected then
    throw <| IO.userError s!"{name}: expected {expected.size} bytes, got {actual.size} bytes"

def hexVal? : Char -> Option UInt8
  | '0' => some 0
  | '1' => some 1
  | '2' => some 2
  | '3' => some 3
  | '4' => some 4
  | '5' => some 5
  | '6' => some 6
  | '7' => some 7
  | '8' => some 8
  | '9' => some 9
  | 'a' => some 10
  | 'b' => some 11
  | 'c' => some 12
  | 'd' => some 13
  | 'e' => some 14
  | 'f' => some 15
  | 'A' => some 10
  | 'B' => some 11
  | 'C' => some 12
  | 'D' => some 13
  | 'E' => some 14
  | 'F' => some 15
  | _ => none

def hexToBytes? (s : String) : Option ByteArray :=
  let rec loop : List Char -> ByteArray -> Option ByteArray
    | [], acc => some acc
    | hi :: lo :: rest, acc => do
        let h ← hexVal? hi
        let l ← hexVal? lo
        loop rest (acc.push (UInt8.ofNat (h.toNat * 16 + l.toNat)))
    | _ :: [], _ => none
  loop s.toList ByteArray.empty

def expectHex (name : String) (actual : ByteArray) (expectedHex : String) : IO Unit := do
  match hexToBytes? expectedHex with
  | none => throw <| IO.userError s!"{name}: invalid expected hex literal"
  | some expected => assertByteArrayEq name actual expected

def hmacKey : ByteArray :=
  let rec loop (i : Nat) (acc : ByteArray) : ByteArray :=
    if _h : i < 20 then
      loop (i + 1) (acc.push 0x0b)
    else
      acc
  loop 0 ByteArray.empty

def main : IO Unit := do
  let shaEmpty ← sha256 ByteArray.empty
  assertEq "sha256 empty length" shaEmpty.size 32
  expectHex "sha256 empty" shaEmpty
    "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

  let shaAbc ← sha256 (bytes "abc")
  assertEq "sha256 abc length" shaAbc.size 32
  expectHex "sha256 abc" shaAbc
    "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"

  let blakeEmpty ← blake3 ByteArray.empty
  assertEq "blake3 empty length" blakeEmpty.size 32
  expectHex "blake3 empty" blakeEmpty
    "af1349b9f5f9a1a6a0404dea36dcc9499bcb25c9adc112b7cc9a93cae41f3262"

  let blakeAbc ← blake3 (bytes "abc")
  assertEq "blake3 abc length" blakeAbc.size 32
  expectHex "blake3 abc" blakeAbc
    "6437b3ac38465133ffb63b75273a8db548c558465d79db03fd359c6cd5bd9d85"

  let mac ← hmacSha256 hmacKey (bytes "Hi There")
  assertEq "hmac sha256 length" mac.size 32
  expectHex "hmac sha256 rfc4231 case 1" mac
    "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7"

  let mac512 ← hmacSha512 hmacKey (bytes "Hi There")
  assertEq "hmac sha512 length" mac512.size 64
  expectHex "hmac sha512 rfc4231 case 1" mac512
    "87aa7cdea5ef619d4ff0b4241a1d6cb02379f4e2ce4ec2787ad0b30545e17cdedaa833b7d6b8a702038b274eaea3f4e4be9d914eeb61f1702e696c203a126854"

  for _ in [0:50] do
    expectHex "repeat sha256 abc" (← sha256 (bytes "abc"))
      "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"

  match ← digest HashAlgorithm.sha256 #[bytes "abc"] with
  | Except.error err => throw <| IO.userError s!"stream sha256 abc failed: {err.code}"
  | Except.ok out =>
    expectHex "stream sha256 abc" out "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"

  match ← digest HashAlgorithm.sha256 #[bytes "ab", bytes "c"] with
  | Except.error err => throw <| IO.userError s!"stream sha256 chunked failed: {err.code}"
  | Except.ok out =>
    expectHex "stream sha256 chunked" out "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"

  match ← digest HashAlgorithm.sha256 #[] with
  | Except.error err => throw <| IO.userError s!"stream sha256 empty failed: {err.code}"
  | Except.ok out =>
    expectHex "stream sha256 empty" out "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

  match ← digest HashAlgorithm.blake3 #[bytes "abc"] with
  | Except.error err => throw <| IO.userError s!"stream blake3 abc failed: {err.code}"
  | Except.ok out =>
    expectHex "stream blake3 abc" out "6437b3ac38465133ffb63b75273a8db548c558465d79db03fd359c6cd5bd9d85"

  match ← init HashAlgorithm.sha256 with
  | Except.error err => throw <| IO.userError s!"stream init failed: {err.code}"
  | Except.ok ctx => do
    match ← update ctx (bytes "abc") with
    | Except.error err =>
        free ctx
        throw <| IO.userError s!"stream update failed: {err.code}"
    | Except.ok () => pure ()
    match ← final ctx with
    | Except.error err =>
        free ctx
        throw <| IO.userError s!"stream final failed: {err.code}"
    | Except.ok out =>
      expectHex "stream manual sha256 abc" out "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
    match ← update ctx (bytes "x") with
    | Except.ok _ =>
        free ctx
        throw <| IO.userError "stream update after final should fail"
    | Except.error err =>
        assertEq "stream finalized code" err.code 3
        free ctx

end CryptoHashTest

def main : IO Unit :=
  CryptoHashTest.main
