namespace ZigLean.Crypto.Dh.FFI

@[extern "lean_ziglean_crypto_x25519_keypair"]
opaque x25519KeypairRaw : @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_x25519_shared_secret"]
opaque x25519SharedSecretRaw : @& ByteArray -> @& ByteArray -> IO ByteArray

end ZigLean.Crypto.Dh.FFI
