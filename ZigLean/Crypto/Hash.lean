import ZigLean.Crypto.Hash.FFI
import ZigLean.Crypto.Hash.Stream

namespace ZigLean.Crypto.Hash

def sha256 (input : ByteArray) : IO ByteArray :=
  FFI.sha256Raw input

def blake3 (input : ByteArray) : IO ByteArray :=
  FFI.blake3Raw input

def blake2b256 (input : ByteArray) : IO ByteArray :=
  FFI.blake2b256Raw input

def blake2s256 (input : ByteArray) : IO ByteArray :=
  FFI.blake2s256Raw input

def blake2b512 (input : ByteArray) : IO ByteArray :=
  FFI.blake2b512Raw input

def hmacSha256 (key message : ByteArray) : IO ByteArray :=
  FFI.hmacSha256Raw key message

def hmacSha512 (key message : ByteArray) : IO ByteArray :=
  FFI.hmacSha512Raw key message

def sha512 (input : ByteArray) : IO ByteArray :=
  FFI.sha512Raw input

def sha3_256 (input : ByteArray) : IO ByteArray :=
  FFI.sha3_256Raw input

def keccak256 (input : ByteArray) : IO ByteArray :=
  FFI.keccak256Raw input

end ZigLean.Crypto.Hash
