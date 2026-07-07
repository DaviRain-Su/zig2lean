const std = @import("std");
const c = @cImport({
    @cInclude("ziglean_random.h");
});

const STATUS_OK: u32 = 0;
const STATUS_TOO_LARGE: u32 = 1;
const STATUS_ALLOC: u32 = 2;

fn setError(out: *c.ZigLeanRandomResult, status: u32) u32 {
    out.* = .{ .status = status, .reserved = 0, .out_len = 0, .out = null };
    return status;
}

fn setSuccess(out: *c.ZigLeanRandomResult, buf: []u8) u32 {
    out.* = .{ .status = STATUS_OK, .reserved = 0, .out_len = @intCast(buf.len), .out = buf.ptr };
    return STATUS_OK;
}

export fn ziglean_random_bytes(len: u64, out_result: *c.ZigLeanRandomResult) u32 {
    const size: usize = @intCast(len);
    const out = std.heap.c_allocator.alloc(u8, size) catch return setError(out_result, STATUS_ALLOC);
    std.crypto.random.bytes(out);
    return setSuccess(out_result, out);
}

export fn ziglean_random_free(ptr: ?[*]u8, len: u64) void {
    if (ptr) |p| {
        std.heap.c_allocator.free(p[0..@intCast(len)]);
    }
}
