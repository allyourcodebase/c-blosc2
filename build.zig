const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const linkage = b.option(std.builtin.LinkMode, "linkage", "linkage to use (default: static)") orelse .static;
    const zstd = b.option(bool, "zstd", "Compile with support for Zstd compression (default: true)") orelse true;

    const lz4_dep = b.dependency("lz4", .{
        .target = target,
        .optimize = optimize,
        .linkage = linkage,
    });
    const zstd_dep = b.dependency("zstd", .{
        .target = target,
        .optimize = optimize,
        .linkage = linkage,
    });
    const c_blosc2_source = b.dependency("c_blosc2", .{});

    const config_header = b.addConfigHeader(.{
        .style = .{ .cmake = c_blosc2_source.path("blosc/config.h.in") },
    }, .{
        .HAVE_ZLIB = false,
        .HAVE_ZLIB_NG = false,
        .HAVE_ZSTD = zstd,
        .HAVE_IPP = false,
        .DLL_EXPORT = if (target.result.os.tag == .windows and linkage == .dynamic)
            "__declspec(dllexport)"
        else
            "",
        .HAVE_PLUGINS = false,
    });

    const c_blosc2_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    // Tells "blosc2.h" to include the "config.h"
    c_blosc2_module.addCMacro("USING_CMAKE", "1");
    c_blosc2_module.addConfigHeader(config_header);
    c_blosc2_module.addIncludePath(c_blosc2_source.path("blosc"));
    c_blosc2_module.addIncludePath(c_blosc2_source.path("include"));
    c_blosc2_module.addCSourceFiles(.{
        .root = c_blosc2_source.path("blosc"),
        .files = &.{
            "blosc2.c",
            "blosclz.c",
            "fastcopy.c",
            "schunk.c",
            "frame.c",
            "stune.c",
            "delta.c",
            "shuffle-generic.c",
            "bitshuffle-generic.c",
            "trunc-prec.c",
            "timestamp.c",
            "sframe.c",
            "directories.c",
            "blosc2-stdio.c",
            "b2nd.c",
            "b2nd_utils.c",
        },
    });

    c_blosc2_module.addCSourceFile(.{ .file = c_blosc2_source.path("blosc/shuffle.c") });
    switch (target.result.cpu.arch) {
        .x86_64 => {
            c_blosc2_module.addCSourceFile(.{ .file = c_blosc2_source.path("blosc/shuffle-sse2.c") });
            c_blosc2_module.addCSourceFile(.{ .file = c_blosc2_source.path("blosc/bitshuffle-sse2.c") });
            c_blosc2_module.addCSourceFile(.{ .file = c_blosc2_source.path("blosc/shuffle-avx2.c") });
            c_blosc2_module.addCSourceFile(.{ .file = c_blosc2_source.path("blosc/bitshuffle-avx2.c") });
            c_blosc2_module.addCSourceFile(.{ .file = c_blosc2_source.path("blosc/bitshuffle-avx512.c") });
        },
        .aarch64 => {
            c_blosc2_module.addCSourceFile(.{ .file = c_blosc2_source.path("blosc/shuffle-neon.c") });
        },
        else => {},
    }

    c_blosc2_module.linkLibrary(lz4_dep.artifact("lz4"));
    if (zstd) {
        c_blosc2_module.linkLibrary(zstd_dep.artifact("zstd"));
    }

    const c_blosc2_library = b.addLibrary(.{
        .name = "blosc2",
        .linkage = linkage,
        .root_module = c_blosc2_module,
    });
    c_blosc2_library.installHeadersDirectory(c_blosc2_source.path("include"), ".", .{});

    b.installArtifact(c_blosc2_library);

    // Examples
    const example_options: ExampleOptions = .{
        .target = target,
        .optimize = optimize,
        .c_blosc2 = c_blosc2_library,
    };
    addExample(b, "contexts", c_blosc2_source.path("examples/contexts.c"), example_options);
    addExample(b, "instrument_codec", c_blosc2_source.path("examples/instrument_codec.c"), example_options);
    addExample(b, "delta_schunk_ex", c_blosc2_source.path("examples/delta_schunk_ex.c"), example_options);
    addExample(b, "multithread", c_blosc2_source.path("examples/multithread.c"), example_options);
    addExample(b, "simple", c_blosc2_source.path("examples/simple.c"), example_options);
    addExample(b, "frame_metalayers", c_blosc2_source.path("examples/frame_metalayers.c"), example_options);
    addExample(b, "noinit", c_blosc2_source.path("examples/noinit.c"), example_options);
    addExample(b, "find_roots", c_blosc2_source.path("examples/find_roots.c"), example_options);
    addExample(b, "schunk_simple", c_blosc2_source.path("examples/schunk_simple.c"), example_options);
    addExample(b, "frame_simple", c_blosc2_source.path("examples/frame_simple.c"), example_options);
    addExample(b, "schunk_postfilter", c_blosc2_source.path("examples/schunk_postfilter.c"), example_options);
    addExample(b, "urcodecs", c_blosc2_source.path("examples/urcodecs.c"), example_options);
    addExample(b, "urfilters", c_blosc2_source.path("examples/urfilters.c"), example_options);
    addExample(b, "frame_vlmetalayers", c_blosc2_source.path("examples/frame_vlmetalayers.c"), example_options);
    addExample(b, "sframe_simple", c_blosc2_source.path("examples/sframe_simple.c"), example_options);
    addExample(b, "frame_backed_schunk", c_blosc2_source.path("examples/frame_backed_schunk.c"), example_options);
    addExample(b, "compress_file", c_blosc2_source.path("examples/compress_file.c"), example_options);
    addExample(b, "decompress_file", c_blosc2_source.path("examples/decompress_file.c"), example_options);
    addExample(b, "frame_offset", c_blosc2_source.path("examples/frame_offset.c"), example_options);
    addExample(b, "frame_roundtrip", c_blosc2_source.path("examples/frame_roundtrip.c"), example_options);
    addExample(b, "get_set_slice", c_blosc2_source.path("examples/get_set_slice.c"), example_options);
    addExample(b, "get_blocksize", c_blosc2_source.path("examples/get_blocksize.c"), example_options);
}

pub const ExampleOptions = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    c_blosc2: *std.Build.Step.Compile,
};

fn addExample(b: *std.Build, name: []const u8, path: std.Build.LazyPath, options: ExampleOptions) void {
    const exe = b.addExecutable(.{
        .name = name,
        .root_module = b.createModule(.{
            .target = options.target,
            .optimize = options.optimize,
            .link_libc = true,
        }),
    });
    exe.root_module.linkLibrary(options.c_blosc2);
    exe.root_module.addCSourceFile(.{
        .file = path,
    });
    b.installArtifact(exe);
}
