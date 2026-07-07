import ZigLean.Random.FFI

namespace ZigLean.Random

def randomBytes (n : Nat) : IO ByteArray := do
  let maxN := UInt64.size - 1
  if h : n > maxN then
    throw <| IO.userError s!"randomBytes: requested size {n} exceeds maximum {maxN}"
  FFI.randomBytesRaw (UInt64.ofNat n)

end ZigLean.Random
