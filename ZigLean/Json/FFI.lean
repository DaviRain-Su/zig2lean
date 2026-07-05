namespace ZigLean.Json.FFI

@[extern "lean_ziglean_json_validate_raw"]
opaque validateRaw : @& ByteArray -> IO UInt32

@[extern "lean_ziglean_json_parse_tokens_raw"]
opaque parseTokensRaw : @& ByteArray -> IO ByteArray

end ZigLean.Json.FFI
