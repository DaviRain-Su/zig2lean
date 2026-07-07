const std = @import("std");
const builtin = @import("builtin");
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

fn fillRandom(buf: []u8) void {
    if (buf.len == 0) return;
    switch (builtin.os.tag) {
        .linux => {
            var pos: usize = 0;
            while (pos < buf.len) {
                const n = std.c.getrandom(buf.ptr + pos, buf.len - pos, 0);
                if (n < 0) @panic("getrandom failed");
                pos += @intCast(n);
            }
        },
        .macos, .ios, .tvos, .watchos, .visionos, .freebsd, .netbsd, .openbsd, .dragonfly => {
            std.c.arc4random_buf(buf.ptr, buf.len);
        },
        else => @compileError("unsupported OS for secure random bytes"),
    }
}

export fn ziglean_random_bytes(len: u64, out_result: *c.ZigLeanRandomResult) u32 {
    if (len > std.math.maxInt(usize)) return setError(out_result, STATUS_TOO_LARGE);
    const size: usize = @intCast(len);
    const out = std.heap.c_allocator.alloc(u8, size) catch return setError(out_result, STATUS_ALLOC);
    fillRandom(out);
    return setSuccess(out_result, out);
}

export fn ziglean_random_free(ptr: ?[*]u8, len: u64) void {
    if (ptr) |p| {
        std.heap.c_allocator.free(p[0..@intCast(len)]);
    }
}
