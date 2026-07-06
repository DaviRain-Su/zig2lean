namespace ZigLean.Compress.FFI

@[extern "lean_ziglean_compress_gzip"]
opaque gzipCompressRaw : @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_compress_gzip_decompress"]
opaque gzipDecompressRaw : @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_compress_zlib"]
opaque zlibCompressRaw : @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_compress_zlib_decompress"]
opaque zlibDecompressRaw : @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_compress_deflate"]
opaque deflateCompressRaw : @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_compress_deflate_decompress"]
opaque deflateDecompressRaw : @& ByteArray -> IO ByteArray

end ZigLean.Compress.FFI