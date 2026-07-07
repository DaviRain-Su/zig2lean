import ZigLean.Crypto.Aes.FFI

namespace ZigLean.Crypto.Aes

/-- AES-256 in CTR mode. Encryption and decryption are the same operation:
the keystream is XORed with the input. `key` must be 32 bytes and `iv` must
be 16 bytes. -/
def aes256Ctr (key iv : ByteArray) (input : ByteArray) : IO ByteArray :=
  FFI.aes256CtrRaw key iv input

/-- AES-256 in CBC mode with PKCS#7 padding. `key` must be 32 bytes and `iv`
must be 16 bytes. -/
def aes256CbcEncrypt (key iv : ByteArray) (input : ByteArray) : IO ByteArray :=
  FFI.aes256CbcEncryptRaw key iv input

/-- AES-256 in CBC mode with PKCS#7 unpadding. -/
def aes256CbcDecrypt (key iv : ByteArray) (ciphertext : ByteArray) : IO ByteArray :=
  FFI.aes256CbcDecryptRaw key iv ciphertext

end ZigLean.Crypto.Aes
