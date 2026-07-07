const std = @import("std");
const c = @cImport({
    @cInclude("ziglean_hash_checksum.h");
});

export fn ziglean_hash_crc32(input: [*]const u8, input_len: u64, out_crc: *u32) u32 {
    var crc = std.hash.crc.Crc32.init();
    crc.update(input[0..@intCast(input_len)]);
    out_crc.* = crc.final();
    return 0;
}

export fn ziglean_hash_crc32c(input: [*]const u8, input_len: u64, out_crc: *u32) u32 {
    var crc = std.hash.crc.Crc32Iscsi.init();
    crc.update(input[0..@intCast(input_len)]);
    out_crc.* = crc.final();
    return 0;
}

export fn ziglean_hash_adler32(input: [*]const u8, input_len: u64, out_adler: *u32) u32 {
    out_adler.* = std.hash.Adler32.hash(input[0..@intCast(input_len)]);
    return 0;
}

export fn ziglean_hash_xxhash64(seed: u64, input: [*]const u8, input_len: u64, out_hash: *u64) u32 {
    out_hash.* = std.hash.XxHash64.hash(seed, input[0..@intCast(input_len)]);
    return 0;
}

export fn ziglean_hash_fnv1a64(input: [*]const u8, input_len: u64, out_hash: *u64) u32 {
    out_hash.* = std.hash.Fnv1a_64.hash(input[0..@intCast(input_len)]);
    return 0;
}

export fn ziglean_hash_crc64ecma(input: [*]const u8, input_len: u64, out_crc: *u64) u32 {
    var crc = std.hash.crc.Crc64Ecma182.init();
    crc.update(input[0..@intCast(input_len)]);
    out_crc.* = crc.final();
    return 0;
}
