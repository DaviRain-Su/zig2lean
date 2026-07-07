namespace ZigLean.Crypto.Aes.FFI

@[extern "lean_ziglean_crypto_aes256_ctr"]
opaque aes256CtrRaw : @& ByteArray -> @& ByteArray -> @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_aes256_cbc_encrypt"]
opaque aes256CbcEncryptRaw : @& ByteArray -> @& ByteArray -> @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_aes256_cbc_decrypt"]
opaque aes256CbcDecryptRaw : @& ByteArray -> @& ByteArray -> @& ByteArray -> IO ByteArray

end ZigLean.Crypto.Aes.FFI
