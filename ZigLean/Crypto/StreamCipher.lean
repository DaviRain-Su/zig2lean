import ZigLean.Crypto.StreamCipher.FFI

namespace ZigLean.Crypto.StreamCipher

/-- ChaCha20 (IETF variant) keyed stream cipher.
Encrypt and decrypt are the same operation: the keystream is XORed with the
input. `key` must be 32 bytes and `nonce` must be 12 bytes. -/
def chacha20Xor (key nonce : ByteArray) (counter : UInt32) (input : ByteArray) : IO ByteArray :=
  FFI.chacha20XorRaw key nonce counter input

/-- XChaCha20 (24-byte nonce extended variant) keyed stream cipher.
`key` must be 32 bytes and `nonce` must be 24 bytes. -/
def xChaCha20Xor (key nonce : ByteArray) (counter : UInt32) (input : ByteArray) : IO ByteArray :=
  FFI.xChaCha20XorRaw key nonce counter input

/-- Original ChaCha20 variant with a 64-bit counter and 8-byte nonce.
Provided for interop with pre-IETF implementations. `key` must be 32 bytes
and `nonce` must be 8 bytes. -/
def chacha20LegacyXor (key nonce : ByteArray) (counter : UInt64) (input : ByteArray) : IO ByteArray :=
  FFI.chacha20LegacyXorRaw key nonce counter input

end ZigLean.Crypto.StreamCipher
