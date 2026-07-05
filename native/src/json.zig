const std = @import("std");
const c = @cImport({
    @cInclude("ziglean_json.h");
});

export fn ziglean_json_validate(input: [*]const u8, input_len: u64) u32 {
    _ = input;
    _ = input_len;
    return 0;
}

export fn ziglean_json_parse_tokens(
    input: [*]const u8,
    input_len: u64,
    out_tokens: *?[*]c.ZigLeanJsonToken,
    out_len: *u64,
    out_error: *c.ZigLeanJsonError,
) u32 {
    _ = input;
    _ = input_len;
    out_tokens.* = null;
    out_len.* = 0;
    out_error.* = .{ .code = 0, .reserved = 0, .offset = 0 };
    return 0;
}

export fn ziglean_json_free_tokens(tokens: ?[*]c.ZigLeanJsonToken, len: u64) void {
    _ = len;
    if (tokens) |_| {}
}
