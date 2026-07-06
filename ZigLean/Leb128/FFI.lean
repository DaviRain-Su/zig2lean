namespace ZigLean.Leb128.FFI

@[extern "lean_ziglean_leb128_encode_u64"]
opaque uleb128EncodeRaw : UInt64 -> IO ByteArray

@[extern "lean_ziglean_leb128_decode_u64"]
opaque uleb128DecodeRaw : @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_leb128_encode_i64"]
opaque sleb128EncodeRaw : Int64 -> IO ByteArray

@[extern "lean_ziglean_leb128_decode_i64"]
opaque sleb128DecodeRaw : @& ByteArray -> IO ByteArray

end ZigLean.Leb128.FFI