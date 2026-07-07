namespace ZigLean.Random.FFI

@[extern "lean_ziglean_random_bytes"]
opaque randomBytesRaw : UInt64 -> IO ByteArray

end ZigLean.Random.FFI
