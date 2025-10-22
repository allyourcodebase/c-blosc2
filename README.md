[![CI](https://github.com/allyourcodebase/c-blosc2/actions/workflows/ci.yaml/badge.svg)](https://github.com/allyourcodebase/c-blosc2/actions)

# c-blosc2

This is [c-blosc2](https://github.com/Blosc/c-blosc2), packaged for [Zig](https://ziglang.org/).

## Installation

First, update your `build.zig.zon`:

```
# Initialize a `zig build` project if you haven't already
zig init
zig fetch --save git+https://github.com/allyourcodebase/c-blosc2.git
```

You can then link `c-blosc2` in your `build.zig` with:

```zig
const c_blosc2_dependency = b.dependency("c_blosc2", .{
    .target = target,
    .optimize = optimize,
});
your_exe.linkLibrary(c_blosc2_dependency.artifact("blosc2"));
```
