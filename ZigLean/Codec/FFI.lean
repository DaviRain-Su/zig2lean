namespace ZigLean.Codec.FFI

@[extern "lean_ziglean_codec_hex_encode_lower"]
opaque hexEncodeLowerRaw : @& ByteArray -> IO String

@[extern "lean_ziglean_codec_hex_decode"]
opaque hexDecodeRaw : @& String -> IO ByteArray

@[extern "lean_ziglean_codec_base64_encode"]
opaque base64EncodeRaw : @& ByteArray -> IO String

@[extern "lean_ziglean_codec_base64_decode"]
opaque base64DecodeRaw : @& String -> IO ByteArray

@[extern "lean_ziglean_codec_base64url_encode"]
opaque base64UrlEncodeRaw : @& ByteArray -> IO String

@[extern "lean_ziglean_codec_base64url_decode"]
opaque base64UrlDecodeRaw : @& String -> IO ByteArray

@[extern "lean_ziglean_codec_base58_encode"]
opaque base58EncodeRaw : @& ByteArray -> IO String

@[extern "lean_ziglean_codec_base58_decode"]
opaque base58DecodeRaw : @& String -> IO ByteArray

@[extern "lean_ziglean_codec_base32_encode"]
opaque base32EncodeRaw : @& ByteArray -> IO String

@[extern "lean_ziglean_codec_base32_decode"]
opaque base32DecodeRaw : @& String -> IO ByteArray

@[extern "lean_ziglean_codec_hex_encode_upper"]
opaque hexEncodeUpperRaw : @& ByteArray -> IO String

@[extern "lean_ziglean_codec_base85_encode"]
opaque base85EncodeRaw : @& ByteArray -> IO String

@[extern "lean_ziglean_codec_base85_decode"]
opaque base85DecodeRaw : @& String -> IO ByteArray

@[extern "lean_ziglean_codec_timing_safe_eq"]
opaque timingSafeEqRaw : @& ByteArray -> @& ByteArray -> IO UInt32

end ZigLean.Codec.FFI
