const std = @import("std");
const c = @cImport({
    @cInclude("ziglean_crypto_kdf.h");
});

const STATUS_OK: u32 = 0;
const STATUS_INVALID: u32 = 1;
const STATUS_ALLOC: u32 = 2;

fn setError(out: *?[*]u8, status: u32) u32 {
    out.* = null;
    return status;
}

fn setSuccess(out: *?[*]u8, buf: []u8) u32 {
    out.* = buf.ptr;
    return STATUS_OK;
}

export fn ziglean_crypto_hkdf_sha256(
    salt: [*]const u8,
    salt_len: u64,
    ikm: [*]const u8,
    ikm_len: u64,
    info: [*]const u8,
    info_len: u64,
    out_len: u64,
    out_bytes: *?[*]u8,
) u32 {
    if (out_len == 0 or out_len > 32 * 255) return setError(out_bytes, STATUS_INVALID);
    const out = std.heap.c_allocator.alloc(u8, @intCast(out_len)) catch return setError(out_bytes, STATUS_ALLOC);
    const prk = std.crypto.kdf.hkdf.HkdfSha256.extract(salt[0..@intCast(salt_len)], ikm[0..@intCast(ikm_len)]);
    std.crypto.kdf.hkdf.HkdfSha256.expand(out, info[0..@intCast(info_len)], prk);
    return setSuccess(out_bytes, out);
}

export fn ziglean_crypto_pbkdf2_sha256(
    password: [*]const u8,
    password_len: u64,
    salt: [*]const u8,
    salt_len: u64,
    rounds: u32,
    out_len: u64,
    out_bytes: *?[*]u8,
) u32 {
    if (out_len == 0) return setError(out_bytes, STATUS_INVALID);
    const out = std.heap.c_allocator.alloc(u8, @intCast(out_len)) catch return setError(out_bytes, STATUS_ALLOC);
    std.crypto.pwhash.pbkdf2(
        out,
        password[0..@intCast(password_len)],
        salt[0..@intCast(salt_len)],
        rounds,
        std.crypto.auth.hmac.sha2.HmacSha256,
    ) catch {
        std.heap.c_allocator.free(out);
        return setError(out_bytes, STATUS_INVALID);
    };
    return setSuccess(out_bytes, out);
}

export fn ziglean_crypto_scrypt(
    password: [*]const u8,
    password_len: u64,
    salt: [*]const u8,
    salt_len: u64,
    ln: u32,
    r: u32,
    p: u32,
    out_len: u64,
    out_bytes: *?[*]u8,
) u32 {
    if (out_len == 0) return setError(out_bytes, STATUS_INVALID);
    const out = std.heap.c_allocator.alloc(u8, @intCast(out_len)) catch return setError(out_bytes, STATUS_ALLOC);
    const params = std.crypto.pwhash.scrypt.Params{
        .ln = @intCast(ln),
        .r = @intCast(r),
        .p = @intCast(p),
    };
    std.crypto.pwhash.scrypt.kdf(
        std.heap.c_allocator,
        out,
        password[0..@intCast(password_len)],
        salt[0..@intCast(salt_len)],
        params,
    ) catch {
        std.heap.c_allocator.free(out);
        return setError(out_bytes, STATUS_INVALID);
    };
    return setSuccess(out_bytes, out);
}

var argon_threaded: std.Io.Threaded = undefined;
var argon_threaded_ready = false;

fn argonIo() std.Io {
    if (!argon_threaded_ready) {
        argon_threaded = std.Io.Threaded.init(std.heap.c_allocator, .{});
        argon_threaded_ready = true;
    }
    return argon_threaded.io();
}

export fn ziglean_crypto_argon2id(
    password: [*]const u8,
    password_len: u64,
    salt: [*]const u8,
    salt_len: u64,
    t: u32,
    m_kib: u32,
    p: u32,
    out_len: u64,
    out_bytes: *?[*]u8,
) u32 {
    if (out_len < 4) return setError(out_bytes, STATUS_INVALID);
    const out = std.heap.c_allocator.alloc(u8, @intCast(out_len)) catch return setError(out_bytes, STATUS_ALLOC);
    const params = std.crypto.pwhash.argon2.Params{
        .t = t,
        .m = m_kib,
        .p = @intCast(p),
    };
    std.crypto.pwhash.argon2.kdf(
        std.heap.c_allocator,
        out,
        password[0..@intCast(password_len)],
        salt[0..@intCast(salt_len)],
        params,
        .argon2id,
        argonIo(),
    ) catch {
        std.heap.c_allocator.free(out);
        return setError(out_bytes, STATUS_INVALID);
    };
    return setSuccess(out_bytes, out);
}

export fn ziglean_crypto_kdf_free(ptr: ?[*]u8, len: u64) void {
    if (ptr) |p| {
        std.heap.c_allocator.free(p[0..@intCast(len)]);
    }
}