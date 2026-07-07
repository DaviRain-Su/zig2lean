import ZigLean.Crypto.Aead.FFI

namespace ZigLean.Crypto.Aead

structure AeadError where
  code : UInt32
  offset : UInt64
  message : String
deriving Repr, BEq

def readU32LE? (b : ByteArray) (off : Nat) : Option UInt32 := do
  if off + 4 > b.size then none else
  let b0 := b[off]!.toUInt32
  let b1 := b[off + 1]!.toUInt32
  let b2 := b[off + 2]!.toUInt32
  let b3 := b[off + 3]!.toUInt32
  some (b0 ||| (b1 <<< 8) ||| (b2 <<< 16) ||| (b3 <<< 24))

def readU64LE? (b : ByteArray) (off : Nat) : Option UInt64 := do
  if off + 8 > b.size then none else
  let rec loop (i factor : Nat) (acc : UInt64) : UInt64 :=
    if _h : i < 8 then
      loop (i + 1) (factor * 256) (acc + UInt64.ofNat (b[off + i]!.toNat * factor))
    else
      acc
  some (loop 0 1 0)

def decodeRawResult (b : ByteArray) : Except AeadError ByteArray := Id.run do
  let some status := readU32LE? b 0
    | return Except.error { code := 9001, offset := 0, message := "short aead result" }
  let some code := readU32LE? b 4
    | return Except.error { code := 9001, offset := 0, message := "short aead result" }
  let some offset := readU64LE? b 8
    | return Except.error { code := 9001, offset := 0, message := "short aead result" }
  if status != 0 then
    return Except.error { code, offset, message := "aead decrypt failed" }
  return Except.ok (b.extract 16 b.size)

def aes256GcmEncrypt (key nonce aad plaintext : ByteArray) : IO ByteArray :=
  FFI.aes256GcmEncryptRaw key nonce aad plaintext

def aes256GcmDecrypt (key nonce aad ciphertextAndTag : ByteArray) : IO (Except AeadError ByteArray) := do
  pure <| decodeRawResult (← FFI.aes256GcmDecryptRaw key nonce aad ciphertextAndTag)

def aes256GcmSivEncrypt (key nonce aad plaintext : ByteArray) : IO ByteArray :=
  FFI.aes256GcmSivEncryptRaw key nonce aad plaintext

def aes256GcmSivDecrypt (key nonce aad ciphertextAndTag : ByteArray) : IO (Except AeadError ByteArray) := do
  pure <| decodeRawResult (← FFI.aes256GcmSivDecryptRaw key nonce aad ciphertextAndTag)

def aegis256Encrypt (key nonce aad plaintext : ByteArray) : IO ByteArray :=
  FFI.aegis256EncryptRaw key nonce aad plaintext

def aegis256Decrypt (key nonce aad ciphertextAndTag : ByteArray) : IO (Except AeadError ByteArray) := do
  pure <| decodeRawResult (← FFI.aegis256DecryptRaw key nonce aad ciphertextAndTag)

def chacha20Poly1305Encrypt (key nonce aad plaintext : ByteArray) : IO ByteArray :=
  FFI.chacha20Poly1305EncryptRaw key nonce aad plaintext

def chacha20Poly1305Decrypt (key nonce aad ciphertextAndTag : ByteArray) : IO (Except AeadError ByteArray) := do
  pure <| decodeRawResult (← FFI.chacha20Poly1305DecryptRaw key nonce aad ciphertextAndTag)

def aes256OcbEncrypt (key nonce aad plaintext : ByteArray) : IO ByteArray :=
  FFI.aes256OcbEncryptRaw key nonce aad plaintext

def aes256OcbDecrypt (key nonce aad ciphertextAndTag : ByteArray) : IO (Except AeadError ByteArray) := do
  pure <| decodeRawResult (← FFI.aes256OcbDecryptRaw key nonce aad ciphertextAndTag)

def aes256SivEncrypt (key nonce aad plaintext : ByteArray) : IO ByteArray :=
  FFI.aes256SivEncryptRaw key nonce aad plaintext

def aes256SivDecrypt (key nonce aad ciphertextAndTag : ByteArray) : IO (Except AeadError ByteArray) := do
  pure <| decodeRawResult (← FFI.aes256SivDecryptRaw key nonce aad ciphertextAndTag)

end ZigLean.Crypto.Aead