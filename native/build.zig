const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const lean_prefix = b.option([]const u8, "lean-prefix", "Lean installation prefix") orelse
        @panic("missing -Dlean-prefix");

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "lean_ziglean",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    lib.root_module.addIncludePath(b.path("include"));
    lib.root_module.addIncludePath(.{ .cwd_relative = b.fmt("{s}/include", .{lean_prefix}) });
    lib.root_module.addCSourceFile(.{
        .file = b.path("c/lean_json.c"),
        .flags = &.{ "-std=c11", "-fno-sanitize=undefined" },
    });
    lib.root_module.addCSourceFile(.{
        .file = b.path("c/lean_crypto_hash.c"),
        .flags = &.{ "-std=c11", "-fno-sanitize=undefined" },
    });
    lib.root_module.addCSourceFile(.{
        .file = b.path("c/lean_codec.c"),
        .flags = &.{ "-std=c11", "-fno-sanitize=undefined" },
    });
    lib.root_module.link_libc = true;
    b.installArtifact(lib);
}
