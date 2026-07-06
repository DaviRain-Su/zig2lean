const std = @import("std");

const STATUS_OK: u32 = 0;
const STATUS_INVALID: u32 = 1;
const STATUS_ALLOC: u32 = 2;
const STATUS_FINALIZED: u32 = 3;

const Algo = enum(u32) {
    sha256 = 1,
    blake3 = 2,
    sha512 = 3,
    sha3_256 = 4,
    keccak256 = 5,
};

const HashCtx = struct {
    finalized: bool,
    state: State,

    const State = union(Algo) {
        sha256: std.crypto.hash.sha2.Sha256,
        blake3: std.crypto.hash.Blake3,
        sha512: std.crypto.hash.sha2.Sha512,
        sha3_256: std.crypto.hash.sha3.Sha3_256,
        keccak256: std.crypto.hash.sha3.Keccak256,
    };
};

fn algoFromId(algo_id: u32) ?Algo {
    return switch (algo_id) {
        1 => .sha256,
        2 => .blake3,
        3 => .sha512,
        4 => .sha3_256,
        5 => .keccak256,
        else => null,
    };
}

fn digestLen(algo: Algo) u64 {
    return switch (algo) {
        .sha256 => 32,
        .blake3 => 32,
        .sha512 => 64,
        .sha3_256 => 32,
        .keccak256 => 32,
    };
}

fn initState(algo: Algo) HashCtx.State {
    return switch (algo) {
        .sha256 => .{ .sha256 = std.crypto.hash.sha2.Sha256.init(.{}) },
        .blake3 => .{ .blake3 = std.crypto.hash.Blake3.init(.{}) },
        .sha512 => .{ .sha512 = std.crypto.hash.sha2.Sha512.init(.{}) },
        .sha3_256 => .{ .sha3_256 = std.crypto.hash.sha3.Sha3_256.init(.{}) },
        .keccak256 => .{ .keccak256 = std.crypto.hash.sha3.Keccak256.init(.{}) },
    };
}

export fn ziglean_crypto_hash_stream_digest_len(algo_id: u32, out_len: *u64) u32 {
    const algo = algoFromId(algo_id) orelse return STATUS_INVALID;
    out_len.* = digestLen(algo);
    return STATUS_OK;
}

export fn ziglean_crypto_hash_stream_init(algo_id: u32, out_handle: *?*anyopaque) u32 {
    const algo = algoFromId(algo_id) orelse return STATUS_INVALID;
    const ctx = std.heap.c_allocator.create(HashCtx) catch return STATUS_ALLOC;
    ctx.* = .{ .finalized = false, .state = initState(algo) };
    out_handle.* = ctx;
    return STATUS_OK;
}

export fn ziglean_crypto_hash_stream_update(
    handle: ?*anyopaque,
    input: [*]const u8,
    input_len: u64,
) u32 {
    const ctx: *HashCtx = @ptrCast(@alignCast(handle orelse return STATUS_INVALID));
    if (ctx.finalized) return STATUS_FINALIZED;
    const bytes = input[0..@intCast(input_len)];
    switch (ctx.state) {
        .sha256 => |*h| h.update(bytes),
        .blake3 => |*h| h.update(bytes),
        .sha512 => |*h| h.update(bytes),
        .sha3_256 => |*h| h.update(bytes),
        .keccak256 => |*h| h.update(bytes),
    }
    return STATUS_OK;
}

export fn ziglean_crypto_hash_stream_final(
    handle: ?*anyopaque,
    out_digest: [*]u8,
    out_len: u64,
) u32 {
    const ctx: *HashCtx = @ptrCast(@alignCast(handle orelse return STATUS_INVALID));
    if (ctx.finalized) return STATUS_FINALIZED;
    switch (ctx.state) {
        .sha256 => |*h| {
            if (out_len < 32) return STATUS_INVALID;
            h.final(out_digest[0..32]);
        },
        .blake3 => |*h| {
            if (out_len < 32) return STATUS_INVALID;
            h.final(out_digest[0..32]);
        },
        .sha512 => |*h| {
            if (out_len < 64) return STATUS_INVALID;
            h.final(out_digest[0..64]);
        },
        .sha3_256 => |*h| {
            if (out_len < 32) return STATUS_INVALID;
            h.final(out_digest[0..32]);
        },
        .keccak256 => |*h| {
            if (out_len < 32) return STATUS_INVALID;
            h.final(out_digest[0..32]);
        },
    }
    ctx.finalized = true;
    return STATUS_OK;
}

export fn ziglean_crypto_hash_stream_free(handle: ?*anyopaque) void {
    if (handle) |ptr| {
        const ctx: *HashCtx = @ptrCast(@alignCast(ptr));
        std.heap.c_allocator.destroy(ctx);
    }
}