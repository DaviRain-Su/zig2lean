namespace ZigLean.Crypto.Hash.FFI

@[extern "lean_ziglean_crypto_sha224"]
opaque sha224Raw : @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_sha256"]
opaque sha256Raw : @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_blake3"]
opaque blake3Raw : @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_blake2b256"]
opaque blake2b256Raw : @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_blake2s256"]
opaque blake2s256Raw : @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_blake2b512"]
opaque blake2b512Raw : @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_hmac_sha256"]
opaque hmacSha256Raw : @& ByteArray -> @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_hmac_sha512"]
opaque hmacSha512Raw : @& ByteArray -> @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_sha384"]
opaque sha384Raw : @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_sha512"]
opaque sha512Raw : @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_sha3_224"]
opaque sha3_224Raw : @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_sha3_256"]
opaque sha3_256Raw : @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_sha3_384"]
opaque sha3_384Raw : @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_sha3_512"]
opaque sha3_512Raw : @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_keccak256"]
opaque keccak256Raw : @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_keccak512"]
opaque keccak512Raw : @& ByteArray -> IO ByteArray

end ZigLean.Crypto.Hash.FFI
