import ZigLean.Random.FFI

namespace ZigLean.Random

def randomBytes (n : Nat) : IO ByteArray :=
  FFI.randomBytesRaw (UInt64.ofNat n)

end ZigLean.Random
