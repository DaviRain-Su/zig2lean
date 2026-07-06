namespace ZigLean.Crypto.Hash.Stream.FFI

@[extern "lean_ziglean_crypto_hash_stream_init"]
opaque initRaw : UInt32 -> IO USize

@[extern "lean_ziglean_crypto_hash_stream_update"]
opaque updateRaw : USize -> @& ByteArray -> IO UInt32

@[extern "lean_ziglean_crypto_hash_stream_final"]
opaque finalRaw : USize -> UInt32 -> IO ByteArray

@[extern "lean_ziglean_crypto_hash_stream_free"]
opaque freeRaw : USize -> IO Unit

end ZigLean.Crypto.Hash.Stream.FFI