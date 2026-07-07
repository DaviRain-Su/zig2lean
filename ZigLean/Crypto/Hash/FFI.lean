namespace ZigLean.Crypto.Hash.FFI

@[extern "lean_ziglean_crypto_sha256"]
opaque sha256Raw : @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_blake3"]
opaque blake3Raw : @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_blake2b256"]
opaque blake2b256Raw : @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_hmac_sha256"]
opaque hmacSha256Raw : @& ByteArray -> @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_hmac_sha512"]
opaque hmacSha512Raw : @& ByteArray -> @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_sha512"]
opaque sha512Raw : @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_sha3_256"]
opaque sha3_256Raw : @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_keccak256"]
opaque keccak256Raw : @& ByteArray -> IO ByteArray

end ZigLean.Crypto.Hash.FFI
