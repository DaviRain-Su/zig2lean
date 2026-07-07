namespace ZigLean.Hash.Checksum.FFI

@[extern "lean_ziglean_hash_crc32"]
opaque crc32Raw : @& ByteArray -> IO UInt32

@[extern "lean_ziglean_hash_crc32c"]
opaque crc32cRaw : @& ByteArray -> IO UInt32

@[extern "lean_ziglean_hash_crc64ecma"]
opaque crc64ecmaRaw : @& ByteArray -> IO UInt64

@[extern "lean_ziglean_hash_adler32"]
opaque adler32Raw : @& ByteArray -> IO UInt32

@[extern "lean_ziglean_hash_xxhash64"]
opaque xxHash64Raw : UInt64 -> @& ByteArray -> IO UInt64

@[extern "lean_ziglean_hash_fnv1a64"]
opaque fnv1a64Raw : @& ByteArray -> IO UInt64

@[extern "lean_ziglean_hash_cityhash64"]
opaque cityhash64Raw : @& ByteArray -> IO UInt64

end ZigLean.Hash.Checksum.FFI
