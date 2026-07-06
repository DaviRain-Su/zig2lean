import ZigLean.Crypto.Hash.FFI

namespace ZigLean.Crypto.Hash

def sha256 (input : ByteArray) : IO ByteArray :=
  FFI.sha256Raw input

def blake3 (input : ByteArray) : IO ByteArray :=
  FFI.blake3Raw input

def hmacSha256 (key message : ByteArray) : IO ByteArray :=
  FFI.hmacSha256Raw key message

end ZigLean.Crypto.Hash
