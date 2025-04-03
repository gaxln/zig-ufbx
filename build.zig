const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var cflags = try std.BoundedArray([]const u8, 64).init(0);
    if (target.result.cpu.arch.isWasm()) {
        try cflags.append("-fno-sanitize=undefined");
    }
    const lib_ufbx = b.addStaticLibrary(.{
        .name = "ufbx_clib",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    lib_ufbx.linkLibCpp();
    lib_ufbx.addCSourceFiles(.{
        .files = &.{
            "src/ufbx.c",
        },
        .flags = cflags.slice(),
    });

    b.installArtifact(lib_ufbx);

    // translate-c the ufbx.h file
    const translateC = b.addTranslateC(.{
        .root_source_file = b.path("src/ufbx.h"),
        .target = b.graph.host,
        .optimize = optimize,
    });

    // build cimgui as module
    const mod_ufbx = b.addModule("ufbx", .{
        .root_source_file = translateC.getOutput(),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    mod_ufbx.linkLibrary(lib_ufbx);
}
