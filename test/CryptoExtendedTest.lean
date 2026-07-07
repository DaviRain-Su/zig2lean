import ZigLean

namespace CryptoExtendedTest

open ZigLean.Crypto.Hash
open ZigLean.Crypto.Kdf
open ZigLean.Crypto.Sign
open ZigLean.Crypto.Aead
open ZigLean.Hash.Checksum
open ZigLean.Leb128

def bytes (s : String) : ByteArray :=
  s.toUTF8

def assertEq [BEq α] [ToString α] (name : String) (actual expected : α) : IO Unit := do
  if actual != expected then
    throw <| IO.userError s!"{name}: expected {expected}, got {actual}"

def hexVal? : Char -> Option UInt8
  | '0' => some 0 | '1' => some 1 | '2' => some 2 | '3' => some 3
  | '4' => some 4 | '5' => some 5 | '6' => some 6 | '7' => some 7
  | '8' => some 8 | '9' => some 9
  | 'a' => some 10 | 'b' => some 11 | 'c' => some 12 | 'd' => some 13
  | 'e' => some 14 | 'f' => some 15
  | 'A' => some 10 | 'B' => some 11 | 'C' => some 12 | 'D' => some 13
  | 'E' => some 14 | 'F' => some 15
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
  | none => throw <| IO.userError s!"{name}: invalid expected hex"
  | some expected =>
    if actual != expected then
      throw <| IO.userError s!"{name}: byte arrays differ"

def repeatByte (n : Nat) (b : UInt8) : ByteArray :=
  let rec loop (i : Nat) (acc : ByteArray) : ByteArray :=
    if _h : i < n then loop (i + 1) (acc.push b) else acc
  loop 0 ByteArray.empty

def expectDecodeOk {α} (name : String) (actual : Except Leb128Error α) (check : α -> Bool) : IO Unit := do
  match actual with
  | Except.ok v =>
    if !check v then
      throw <| IO.userError s!"{name}: unexpected decoded value"
  | Except.error err => throw <| IO.userError s!"{name}: decode failed with {err.code}"

def main : IO Unit := do
  expectHex "sha512 empty" (← sha512 ByteArray.empty)
    "cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e"
  expectHex "sha3_256 empty" (← sha3_256 ByteArray.empty)
    "a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a"
  expectHex "keccak256 empty" (← keccak256 ByteArray.empty)
    "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"

  let salt :=
    (ByteArray.empty.push 0x00).push 0x01 |>.push 0x02 |>.push 0x03 |>.push 0x04 |>.push 0x05
      |>.push 0x06 |>.push 0x07 |>.push 0x08 |>.push 0x09 |>.push 0x0a |>.push 0x0b |>.push 0x0c
  let info :=
    (ByteArray.empty.push 0xf0).push 0xf1 |>.push 0xf2 |>.push 0xf3 |>.push 0xf4 |>.push 0xf5
      |>.push 0xf6 |>.push 0xf7 |>.push 0xf8 |>.push 0xf9
  let hkdfOut ← hkdfSha256 salt (repeatByte 22 0x0b) info 42
  assertEq "hkdf length" hkdfOut.size 42
  expectHex "hkdf sample" hkdfOut
    "3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865"

  let pbkdfOut ← pbkdf2Sha256 (bytes "password") (bytes "salt") 1 32
  assertEq "pbkdf2 length" pbkdfOut.size 32
  expectHex "pbkdf2 sample" pbkdfOut
    "120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b"

  let scryptOut ← scrypt (bytes "password") (bytes "saltsalt") 4 1 1 32
  assertEq "scrypt length" scryptOut.size 32
  assertEq "scrypt repeat" scryptOut (← scrypt (bytes "password") (bytes "saltsalt") 4 1 1 32)

  let argonOut ← argon2id (bytes "password") (repeatByte 16 0x02) 1 8 1 32
  assertEq "argon2id length" argonOut.size 32
  assertEq "argon2id repeat" argonOut (← argon2id (bytes "password") (repeatByte 16 0x02) 1 8 1 32)

  let seed := repeatByte 32 0x01
  let msg := bytes "test message"
  let sig ← ed25519Sign seed msg
  assertEq "ed25519 sig len" sig.size 64
  let kpPub := repeatByte 32 0x3d -- placeholder: verify with wrong key should fail
  let validWrong ← ed25519Verify kpPub msg sig
  if validWrong then
    throw <| IO.userError "ed25519 verify should fail with wrong key"

  let crc ← crc32 (bytes "123456789")
  assertEq "crc32" crc 0xcbf43926

  let crcC ← crc32c (bytes "123456789")
  assertEq "crc32c" crcC 0xe3069283

  let adler ← adler32 (bytes "123456789")
  assertEq "adler32" adler 0x091e01de
  assertEq "adler32 empty" (← adler32 ByteArray.empty) 1

  let hash ← xxHash64 0 (bytes "hello")
  assertEq "xxhash64 hello repeat" hash (← xxHash64 0 (bytes "hello"))

  let fnv ← fnv1a64 (bytes "hello")
  assertEq "fnv1a64 hello" fnv 0xa430d84680aabd0b
  assertEq "fnv1a64 empty" (← fnv1a64 ByteArray.empty) 0xcbf29ce484222325
  assertEq "fnv1a64 abc" (← fnv1a64 (bytes "abc")) 0xe71fa2190541574b

  let encoded ← uleb128Encode 300
  assertEq "uleb128 300 bytes" encoded.size 2
  expectDecodeOk "uleb128 300 decode" (← uleb128Decode encoded) (· == 300)

  let senc ← sleb128Encode (-42)
  expectDecodeOk "sleb128 -42 decode" (← sleb128Decode senc) (· == -42)

  let key := repeatByte 32 0x69
  let nonce := repeatByte 12 0x42
  let plain := bytes "secret"
  let enc ← aes256GcmEncrypt key nonce ByteArray.empty plain
  assertEq "aes gcm enc len" enc.size (plain.size + 16)
  match ← aes256GcmDecrypt key nonce ByteArray.empty enc with
  | Except.ok out => if out != plain then throw <| IO.userError "aes gcm roundtrip mismatch"
  | Except.error err => throw <| IO.userError s!"aes gcm decrypt failed: {err.code}"

  let chEnc ← chacha20Poly1305Encrypt key nonce ByteArray.empty plain
  match ← chacha20Poly1305Decrypt key nonce ByteArray.empty chEnc with
  | Except.ok out => if out != plain then throw <| IO.userError "chacha roundtrip mismatch"
  | Except.error err => throw <| IO.userError s!"chacha decrypt failed: {err.code}"

end CryptoExtendedTest

def main : IO Unit :=
  CryptoExtendedTest.main