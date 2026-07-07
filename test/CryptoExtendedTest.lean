import ZigLean

set_option maxRecDepth 200000

namespace CryptoExtendedTest

open ZigLean.Crypto.Hash
open ZigLean.Crypto.Kdf
open ZigLean.Crypto.Sign
open ZigLean.Crypto.Aead
open ZigLean.Crypto.Dh
open ZigLean.Crypto.StreamCipher
open ZigLean.Crypto.Aes
open ZigLean.Codec
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

  let p256sig ← p256Sign seed msg
  assertEq "p256 sig len" p256sig.size 64
  let p256PubWrong := repeatByte 33 0x3d
  let p256ValidWrong ← p256Verify p256PubWrong msg p256sig
  if p256ValidWrong then
    throw <| IO.userError "p256 verify should fail with wrong key"

  let seedA := repeatByte 32 0x01
  let seedB := repeatByte 32 0x02
  let kpA ← x25519Keypair seedA
  let kpB ← x25519Keypair seedB
  assertEq "x25519 keypair len" kpA.size 64
  let skA := kpA.extract 0 32
  let pkA := kpA.extract 32 64
  let skB := kpB.extract 0 32
  let pkB := kpB.extract 32 64
  let sharedA ← x25519SharedSecret skA pkB
  let sharedB ← x25519SharedSecret skB pkA
  assertEq "x25519 shared secret len" sharedA.size 32
  if sharedA != sharedB then
    throw <| IO.userError "x25519 shared secrets do not match"

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

  let crc64 ← crc64ecma (bytes "hello")
  assertEq "crc64ecma hello" crc64 0x40544a306137b6ec
  assertEq "crc64ecma empty" (← crc64ecma ByteArray.empty) 0x0000000000000000
  assertEq "crc64ecma abc" (← crc64ecma (bytes "abc")) 0x66501a349a0e0855

  let city ← cityhash64 (bytes "hello")
  assertEq "cityhash64 hello" city 0xb48be5a931380ce8
  assertEq "cityhash64 empty" (← cityhash64 ByteArray.empty) 0x9ae16a3b2f90404f
  assertEq "cityhash64 abc" (← cityhash64 (bytes "abc")) 0x24a5b3a074e7f369

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

  let sivEnc ← aes256GcmSivEncrypt key nonce ByteArray.empty plain
  assertEq "aes256gcm-siv enc len" sivEnc.size (plain.size + 16)
  match ← aes256GcmSivDecrypt key nonce ByteArray.empty sivEnc with
  | Except.ok out => if out != plain then throw <| IO.userError "aes256gcm-siv roundtrip mismatch"
  | Except.error err => throw <| IO.userError s!"aes256gcm-siv decrypt failed: {err.code}"

  let aegisNonce := repeatByte 32 0x42
  let aegisEnc ← aegis256Encrypt key aegisNonce ByteArray.empty plain
  assertEq "aegis256 enc len" aegisEnc.size (plain.size + 16)
  match ← aegis256Decrypt key aegisNonce ByteArray.empty aegisEnc with
  | Except.ok out => if out != plain then throw <| IO.userError "aegis256 roundtrip mismatch"
  | Except.error err => throw <| IO.userError s!"aegis256 decrypt failed: {err.code}"

  -- ChaCha20 (IETF variant) stream cipher: symmetric xor, so a second
  -- application restores the plaintext. Validates the FFI/ABI end-to-end.
  let chachaKey := repeatByte 32 0x69
  let chachaNonce := repeatByte 12 0x42
  let rfcPlain := bytes "Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it."
  let chachaCt ← chacha20Xor chachaKey chachaNonce 1 rfcPlain
  assertEq "chacha20 ct len" chachaCt.size rfcPlain.size
  let chachaBack ← chacha20Xor chachaKey chachaNonce 1 chachaCt
  assertEq "chacha20 roundtrip" chachaBack rfcPlain

  -- XChaCha20 (24-byte nonce variant) roundtrip
  let xKey := repeatByte 32 0x05
  let xNonce := repeatByte 24 0x07
  let xCt ← xChaCha20Xor xKey xNonce 0 rfcPlain
  assertEq "xchacha20 ct len" xCt.size rfcPlain.size
  let xBack ← xChaCha20Xor xKey xNonce 0 xCt
  assertEq "xchacha20 roundtrip" xBack rfcPlain

  -- Original ChaCha20 variant (8-byte nonce) cross-checked against an
  -- independently generated vector (Python `cryptography` ChaCha20).
  let mut legKey := ByteArray.empty
  for i in [0:32] do
    legKey := legKey.push (UInt8.ofNat i)
  let legNonce := ByteArray.empty
    |>.push 0x07 |>.push 0x06 |>.push 0x05 |>.push 0x04
    |>.push 0x03 |>.push 0x02 |>.push 0x01 |>.push 0x00
  let legPt := bytes "The quick brown fox jumps over the lazy dog."
  let legCt ← chacha20LegacyXor legKey legNonce 0 legPt
  expectHex "chacha20 legacy vector" legCt
    "4a14a89a88e3da973615140818636e86a6a1df9b74a72e8c21faf11e37641163f5bf76848f2e0898715a50ee"

  -- AES-256 (CTR and CBC), cross-checked against Python `cryptography`.
  let mut aesKey := ByteArray.empty
  for i in [0:32] do
    aesKey := aesKey.push (UInt8.ofNat i)
  let mut aesIv := ByteArray.empty
  for i in [0:16] do
    aesIv := aesIv.push (UInt8.ofNat i)
  let aesPt := bytes "The quick brown fox jumps over the lazy dog. AES CBC test."

  let ctrCt ← aes256Ctr aesKey aesIv aesPt
  expectHex "aes256 ctr vector" ctrCt
    "0e066177798e18f59b0e374f6db4c8b2069c68f5a9f0352d26369427179700bb740057375bbfb584df8e6c8bc55082c1b688453108e4c29c1d6e"
  -- CTR is symmetric: re-applying recovers the plaintext.
  let ctrBack ← aes256Ctr aesKey aesIv ctrCt
  assertEq "aes256 ctr roundtrip" ctrBack aesPt

  let cbcCt ← aes256CbcEncrypt aesKey aesIv aesPt
  expectHex "aes256 cbc vector" cbcCt
    "4846f83aa211e239aa62a21f527f089ee9ddbead30ee15d4e79b607a621b97be33780183ae2b67b6979e33e391df7c127855ed7a01444a1d5184411d9ae9841d"
  let cbcBack ← aes256CbcDecrypt aesKey aesIv cbcCt
  assertEq "aes256 cbc roundtrip" cbcBack aesPt

  -- AES-256-OCB, cross-checked against PyCryptodome (RFC 7253 vector).
  let mut ocKey := ByteArray.empty
  for i in [0:32] do
    ocKey := ocKey.push (UInt8.ofNat i)
  let mut ocNonce := ByteArray.empty
  for i in [0:12] do
    ocNonce := ocNonce.push (UInt8.ofNat i)
  let ocAad := bytes "header-data"
  let ocPt := bytes "The quick brown fox jumps over the lazy dog. OCB test."
  let ocCt ← aes256OcbEncrypt ocKey ocNonce ocAad ocPt
  expectHex "aes256ocb vector" ocCt
    "c5f4ebecf0290cefec9998cb2ee5492962d294cce15db3b4427ea5cacdb70d715d9b8ce7c59c3cf19bbdd51778ee7f5f852f612916d4aeeba8d970f0da2b0468614a683b6f93"
  match ← aes256OcbDecrypt ocKey ocNonce ocAad ocCt with
  | Except.ok out => if out != ocPt then throw <| IO.userError "aes256ocb roundtrip mismatch"
  | Except.error err => throw <| IO.userError s!"aes256ocb decrypt failed: {err.code}"
  -- tamper detection
  let mut ocTampered := ocCt
  let ocFlip := UInt8.ofNat (ocTampered[0]!.toNat ^^^ 0xff)
  ocTampered := ocTampered.set! 0 ocFlip
  match ← aes256OcbDecrypt ocKey ocNonce ocAad ocTampered with
  | Except.ok _ => throw <| IO.userError "aes256ocb should have rejected tampered ct"
  | Except.error _ => pure ()

  -- AES-256-SIV (RFC 5297), roundtrip + tamper detection.
  let mut sivKey := ByteArray.empty
  for i in [0:64] do
    sivKey := sivKey.push (UInt8.ofNat i)
  let sivAad := bytes "siv-associated-data"
  let sivPt := bytes "Deterministic authenticated encryption with SIV."
  let sivCt ← aes256SivEncrypt sivKey ByteArray.empty sivAad sivPt
  match ← aes256SivDecrypt sivKey ByteArray.empty sivAad sivCt with
  | Except.ok out => if out != sivPt then throw <| IO.userError "aes256siv roundtrip mismatch"
  | Except.error err => throw <| IO.userError s!"aes256siv decrypt failed: {err.code}"
  let mut sivTampered := sivCt
  let sivFlip := UInt8.ofNat (sivTampered[0]!.toNat ^^^ 0xff)
  sivTampered := sivTampered.set! 0 sivFlip
  match ← aes256SivDecrypt sivKey ByteArray.empty sivAad sivTampered with
  | Except.ok _ => throw <| IO.userError "aes256siv should have rejected tampered ct"
  | Except.error _ => pure ()

  -- Codec: Base16 upper, Base85, and constant-time comparison.
  let codecPt := bytes "The quick brown fox jumps over the lazy dog."
  let hexUpper ← hexEncodeUpper codecPt
  assertEq "hex upper" hexUpper "54686520717569636B2062726F776E20666F78206A756D7073206F76657220746865206C617A7920646F672E"
  let hexLower ← hexEncodeLower codecPt
  assertEq "hex lower" hexLower "54686520717569636b2062726f776e20666f78206a756d7073206f76657220746865206c617a7920646f672e"

  let b85 ← base85Encode codecPt
  assertEq "base85 vector" b85 "<+ohcEHPu*CER),Dg-(AAoDo:C3=B4F!,CEATAo8BOr<&@=!2AA8c*5"
  match ← base85Decode b85 with
  | Except.ok out => if out != codecPt then throw <| IO.userError "base85 roundtrip mismatch"
  | Except.error err => throw <| IO.userError s!"base85 decode failed: {err.code}"

  let eqSame ← timingSafeEq codecPt codecPt
  if not eqSame then throw <| IO.userError "timingSafeEq should report equal"
  let diff := ByteArray.empty
    |>.push (UInt8.ofNat 0x00) |>.push (UInt8.ofNat 0x01) |>.push (UInt8.ofNat 0x02)
  let sameLen := ByteArray.empty
    |>.push (UInt8.ofNat 0x00) |>.push (UInt8.ofNat 0x01) |>.push (UInt8.ofNat 0x03)
  let eqDiff ← timingSafeEq diff sameLen
  if eqDiff then throw <| IO.userError "timingSafeEq should report not equal"

end CryptoExtendedTest

def main : IO Unit :=
  CryptoExtendedTest.main