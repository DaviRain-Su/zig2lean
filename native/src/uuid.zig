const std = @import("std");
const random = @import("random.zig");
const c = @cImport({
    @cInclude("ziglean_uuid.h");
});

const STATUS_OK: u32 = 0;
const STATUS_ALLOC: u32 = 1;
const STATUS_RANDOM: u32 = 2;

const UUID_LEN: usize = 36;

fn setError(out: *c.ZigLeanUuidResult, status: u32) u32 {
    out.* = .{ .status = status, .reserved = 0, .out_len = 0, .out = null };
    return status;
}

fn setSuccess(out: *c.ZigLeanUuidResult, buf: []u8) u32 {
    out.* = .{ .status = STATUS_OK, .reserved = 0, .out_len = @intCast(buf.len), .out = buf.ptr };
    return STATUS_OK;
}

fn hexChar(nibble: u4) u8 {
    return "0123456789abcdef"[nibble];
}

export fn ziglean_uuid_v4(out_result: *c.ZigLeanUuidResult) u32 {
    var bytes: [16]u8 = undefined;
    const status = random.fillRandom(&bytes);
    if (status != STATUS_OK) return setError(out_result, status);

    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;

    const out = std.heap.c_allocator.alloc(u8, UUID_LEN) catch return setError(out_result, STATUS_ALLOC);

    var out_idx: usize = 0;
    for (bytes, 0..) |b, i| {
        if (i == 4 or i == 6 or i == 8 or i == 10) {
            out[out_idx] = '-';
            out_idx += 1;
        }
        out[out_idx] = hexChar(@truncate(b >> 4));
        out[out_idx + 1] = hexChar(@truncate(b & 0x0F));
        out_idx += 2;
    }

    return setSuccess(out_result, out);
}

export fn ziglean_uuid_free(ptr: ?[*]u8, len: u64) void {
    if (len > std.math.maxInt(usize)) return;
    if (ptr) |p| {
        std.heap.c_allocator.free(p[0..@intCast(len)]);
    }
}

test "ziglean_uuid_v4 produces a valid UUID v4 string" {
    var res: c.ZigLeanUuidResult = undefined;
    const status = ziglean_uuid_v4(&res);
    try std.testing.expectEqual(STATUS_OK, status);
    try std.testing.expectEqual(UUID_LEN, res.out_len);

    const s = res.out[0..res.out_len];
    try std.testing.expectEqual(UUID_LEN, s.len);

    // Verify separators at the expected positions.
    try std.testing.expectEqual('-', s[8]);
    try std.testing.expectEqual('-', s[13]);
    try std.testing.expectEqual('-', s[18]);
    try std.testing.expectEqual('-', s[23]);

    // Verify version nibble (4) at position 14.
    try std.testing.expectEqual('4', s[14]);

    // Verify variant bits (10xxxxxx) at position 19.
    const variant_char = s[19];
    try std.testing.expect(variant_char == '8' or variant_char == '9' or variant_char == 'a' or variant_char == 'b');

    // Verify all other characters are hex digits.
    for (s, 0..) |ch, i| {
        if (i == 8 or i == 13 or i == 18 or i == 23) {
            try std.testing.expectEqual('-', ch);
        } else {
            try std.testing.expect(std.ascii.isHex(ch));
        }
    }

    ziglean_uuid_free(res.out, res.out_len);
}
