const std = @import("std");
const flate = std.compress.flate;
const Compress = flate.Compress;
const Decompress = flate.Decompress;
const c = @cImport({
    @cInclude("ziglean_compress.h");
});

const STATUS_OK: u32 = 0;
const STATUS_INVALID: u32 = 1;
const STATUS_CHECKSUM: u32 = 2;
const STATUS_ALLOC: u32 = 3;

fn setError(out: *c.ZigLeanCompressResult, status: u32) u32 {
    out.* = .{ .status = status, .reserved = 0, .out_len = 0, .error_offset = 0, .out = null };
    return status;
}

fn setSuccess(out: *c.ZigLeanCompressResult, buf: []u8) u32 {
    out.* = .{ .status = STATUS_OK, .reserved = 0, .out_len = @intCast(buf.len), .error_offset = 0, .out = buf.ptr };
    return STATUS_OK;
}

fn allocBytes(len: usize) ![]u8 {
    return std.heap.c_allocator.alloc(u8, len);
}

fn compressOneShot(input: []const u8, container: flate.Container, out_result: *c.ZigLeanCompressResult) u32 {
    const capacity = @max(input.len + container.size() + 64, 128);
    var aw = std.Io.Writer.Allocating.initCapacity(std.heap.c_allocator, capacity) catch {
        return setError(out_result, STATUS_ALLOC);
    };
    defer aw.deinit();

    var window: [flate.max_window_len]u8 = undefined;
    var compressor = Compress.init(&aw.writer, &window, container, .default) catch {
        return setError(out_result, STATUS_ALLOC);
    };
    compressor.writer.writeAll(input) catch {
        return setError(out_result, STATUS_INVALID);
    };
    compressor.finish() catch {
        return setError(out_result, STATUS_INVALID);
    };

    const written = aw.written();
    const out = allocBytes(written.len) catch return setError(out_result, STATUS_ALLOC);
    @memcpy(out, written);
    return setSuccess(out_result, out);
}

fn decompressOneShot(input: []const u8, container: flate.Container, out_result: *c.ZigLeanCompressResult) u32 {
    var reader: std.Io.Reader = .fixed(input);
    var aw = std.Io.Writer.Allocating.init(std.heap.c_allocator);
    defer aw.deinit();

    var decompressor = Decompress.init(&reader, container, &.{});
    _ = decompressor.reader.streamRemaining(&aw.writer) catch {
        const status: u32 = if (decompressor.err) |err| switch (err) {
            error.WrongGzipChecksum, error.WrongGzipSize, error.WrongZlibChecksum => STATUS_CHECKSUM,
            else => STATUS_INVALID,
        } else STATUS_INVALID;
        return setError(out_result, status);
    };

    const written = aw.written();
    const out = allocBytes(written.len) catch return setError(out_result, STATUS_ALLOC);
    @memcpy(out, written);
    return setSuccess(out_result, out);
}

fn exportCompress(input: [*]const u8, input_len: u64, out_result: *c.ZigLeanCompressResult, container: flate.Container) u32 {
    return compressOneShot(input[0..@intCast(input_len)], container, out_result);
}

fn exportDecompress(input: [*]const u8, input_len: u64, out_result: *c.ZigLeanCompressResult, container: flate.Container) u32 {
    return decompressOneShot(input[0..@intCast(input_len)], container, out_result);
}

export fn ziglean_compress_gzip(input: [*]const u8, input_len: u64, out_result: *c.ZigLeanCompressResult) u32 {
    return exportCompress(input, input_len, out_result, .gzip);
}

export fn ziglean_compress_gzip_decompress(input: [*]const u8, input_len: u64, out_result: *c.ZigLeanCompressResult) u32 {
    return exportDecompress(input, input_len, out_result, .gzip);
}

export fn ziglean_compress_zlib(input: [*]const u8, input_len: u64, out_result: *c.ZigLeanCompressResult) u32 {
    return exportCompress(input, input_len, out_result, .zlib);
}

export fn ziglean_compress_zlib_decompress(input: [*]const u8, input_len: u64, out_result: *c.ZigLeanCompressResult) u32 {
    return exportDecompress(input, input_len, out_result, .zlib);
}

export fn ziglean_compress_deflate(input: [*]const u8, input_len: u64, out_result: *c.ZigLeanCompressResult) u32 {
    return exportCompress(input, input_len, out_result, .raw);
}

export fn ziglean_compress_deflate_decompress(input: [*]const u8, input_len: u64, out_result: *c.ZigLeanCompressResult) u32 {
    return exportDecompress(input, input_len, out_result, .raw);
}

export fn ziglean_compress_free(ptr: ?[*]u8, len: u64) void {
    if (ptr) |p| {
        std.heap.c_allocator.free(p[0..@intCast(len)]);
    }
}