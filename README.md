# art :art:

art is a [Zig](https://ziglang.org/) ⚡ module used to build
[WebAssembly](https://webassembly.org/) binaries rendering to a
[HTML canvas](https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API).

> [!IMPORTANT]
> You might want to install the [art-init](https://github.com/peterhellberg/art-init) tool
> and use that instead of manually creating the files needed to use this library.

## Usage

You can have `zig build` retrieve the `art` module if you specify it as a dependency.

### Create a `build.zig.zon` that looks something like this:
```zig
.{
    .name = .art_canvas,
    .version = "0.0.0",
    .fingerprint = 0x0000000000,
    .paths = .{""},
    .dependencies = .{
        .art = .{
            .url = "https://github.com/peterhellberg/art/archive/refs/tags/v0.0.9.tar.gz",
        },
    },
}
```

> [!NOTE]
> If you leave out the hash then `zig build` will tell you that it is missing the hash, and what it is.
> Another way to get the hash is to use `zig fetch`, this is probably how you _should_ do it :)

### Download `index.html` and `script.js` from `art-init`

```console
wget https://raw.githubusercontent.com/peterhellberg/art-init/refs/heads/main/content/index.html
wget https://raw.githubusercontent.com/peterhellberg/art-init/refs/heads/main/content/script.js
```

### Then you can add the module in your `build.zig` like this:

```zig
const std = @import("std");

const number_of_pages = 4;

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "art-canvas",
        .root_source_file = b.path("src/canvas.zig"),
        .target = b.resolveTargetQuery(.{
            .cpu_arch = .wasm32,
            .os_tag = .freestanding,
        }),
        .optimize = .ReleaseSmall,
        .strip = true,
    });

    exe.root_module.addImport("art", b.dependency("art", .{}).module("art"));

    exe.root_module.export_symbol_names = &[_][]const u8{
        "start",
        "update",
        "draw",
        "fps",
        "width",
        "height",
        "offset",
    };

    exe.entry = .disabled;
    exe.export_memory = true;
    exe.initial_memory = std.wasm.page_size * number_of_pages;
    exe.max_memory = std.wasm.page_size * number_of_pages;
    exe.stack_size = 512;

    b.installArtifact(exe);
}
```

### In your `src/canvas.zig` you should now be able to:

```zig
const art = @import("art");

var canvas: art.Canvas(16, 9) = .{};

export fn start() void {
    art.log("Hello from Zig!");
}

export fn update(pad: u32) void {
    _ = pad; // autofix
}

export fn draw() void {
    canvas.clear(.{ 0x7C, 0xAF, 0x3C, 0xFF });
}

export fn fps() usize {
    return 60;
}

export fn width() usize {
    return canvas.width;
}

export fn height() usize {
    return canvas.height;
}

export fn offset() [*]u8 {
    return canvas.offset();
}
```
