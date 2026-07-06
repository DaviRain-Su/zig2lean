namespace ZigLean.Crypto.Aead.FFI

@[extern "lean_ziglean_crypto_aes256gcm_encrypt"]
opaque aes256GcmEncryptRaw : @& ByteArray -> @& ByteArray -> @& ByteArray -> @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_aes256gcm_decrypt"]
opaque aes256GcmDecryptRaw : @& ByteArray -> @& ByteArray -> @& ByteArray -> @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_chacha20poly1305_encrypt"]
opaque chacha20Poly1305EncryptRaw : @& ByteArray -> @& ByteArray -> @& ByteArray -> @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_chacha20poly1305_decrypt"]
opaque chacha20Poly1305DecryptRaw : @& ByteArray -> @& ByteArray -> @& ByteArray -> @& ByteArray -> IO ByteArray

end ZigLean.Crypto.Aead.FFI