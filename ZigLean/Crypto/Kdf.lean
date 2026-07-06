import ZigLean.Crypto.Kdf.FFI

namespace ZigLean.Crypto.Kdf

def hkdfSha256 (salt ikm info : ByteArray) (outLen : Nat) : IO ByteArray :=
  FFI.hkdfSha256Raw salt ikm info (UInt64.ofNat outLen)

def pbkdf2Sha256 (password salt : ByteArray) (rounds : UInt32) (outLen : Nat) : IO ByteArray :=
  FFI.pbkdf2Sha256Raw password salt rounds (UInt64.ofNat outLen)

def scrypt (password salt : ByteArray) (ln r p : UInt32) (outLen : Nat) : IO ByteArray :=
  FFI.scryptRaw password salt ln r p (UInt64.ofNat outLen)

def argon2id (password salt : ByteArray) (t mKiB p : UInt32) (outLen : Nat) : IO ByteArray :=
  FFI.argon2idRaw password salt t mKiB p (UInt64.ofNat outLen)

end ZigLean.Crypto.Kdf