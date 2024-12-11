const std = @import("std");

pub fn Canvas(comptime WIDTH: usize, comptime HEIGHT: usize) type {
    return struct {
        width: usize = WIDTH,
        height: usize = HEIGHT,
        buf: [HEIGHT][WIDTH][4]u8 = std.mem.zeroes([HEIGHT][WIDTH][4]u8),

        const Self = @This();

        pub fn offset(self: *Self) [*]u8 {
            return @ptrCast(&self.buf);
        }

        pub fn clear(self: *Self, c: RGBA) void {
            for (&self.buf) |*row| {
                for (row) |*square| {
                    square.* = c;
                }
            }
        }

        pub fn fill(self: *Self, color: *const fn (x: i32, y: i32) RGBA) void {
            for (&self.buf, 0..) |*row, y| {
                for (row, 0..) |*square, x| {
                    const c = color(@intCast(x), @intCast(y));
                    if (c[3] > 0) square.* = c;
                }
            }
        }

        pub fn set(self: *Self, x: i32, y: i32, c: RGB) void {
            if (x < 0 or x >= self.width or y < 0 or y >= self.height) return;

            self.buf[@intCast(y)][@intCast(x)] = .{ c[0], c[1], c[2], 255 };
        }

        pub fn seta(self: *Self, x: i32, y: i32, c: RGBA) void {
            if (x < 0 or x >= self.width or y < 0 or y >= self.height) return;

            self.buf[y][x] = c;
        }

        pub fn hline(self: *Self, x: i32, y: i32, w: usize, color: RGB) void {
            self.rect(x, y, .{ .size = .{ w, 1 }, .color = color });
        }

        pub fn vline(self: *Self, x: i32, y: i32, h: usize, color: RGB) void {
            self.rect(x, y, .{ .size = .{ 1, h }, .color = color });
        }

        pub fn rect(self: *Self, x: i32, y: i32, args: rectArgs) void {
            const ux: usize = @intCast(x);
            const uy: usize = @intCast(y);

            for (ux..ux + args.size[0]) |rx| {
                for (uy..uy + args.size[1]) |ry| {
                    self.set(@intCast(rx), @intCast(ry), args.color);
                }
            }
        }

        pub fn box(self: *Self, x: i32, y: i32, args: boxArgs) void {
            const c = args.color;
            const w = args.size[0];
            const h = args.size[1];

            const bw = if (args.border[0] > w) w else args.border[0];
            const bh = if (args.border[1] > h) h else args.border[1];

            if (args.fill) {
                self.rect(x + bw, y + bh, .{
                    .size = args.size -| args.border * Size{ 2, 2 },
                    .color = args.fillColor,
                });
            }

            self.rect(x, y, .{ .size = .{ w, bh }, .color = c });
            self.rect(x, y + h - bh, .{ .size = .{ w, bh }, .color = c });
            self.rect(x, y + bh, .{ .size = .{ bw, h - bh }, .color = c });
            self.rect(x + w - bw, y + bh, .{ .size = .{ bw, h - bh }, .color = c });
        }
    };
}

pub const RGB = @Vector(3, u8);
pub const RGBA = @Vector(4, u8);

pub fn rgb(hex: u32) RGB {
    return .{
        @intCast(hex >> 16 & 0xFF),
        @intCast(hex >> 8 & 0xFF),
        @intCast(hex & 0xFF),
    };
}

pub fn rgba(hexa: u32) RGBA {
    return .{
        @intCast(hexa >> 24 & 0xFF),
        @intCast(hexa >> 16 & 0xFF),
        @intCast(hexa >> 8 & 0xFF),
        @intCast(hexa & 0xFF),
    };
}

extern "env" fn Log(ptr: [*]const u8, size: u32) void;

pub fn log(message: []const u8) void {
    Log(message.ptr, message.len);
}

pub const Sym = enum {
    x,
    z,
    left,
    right,
    up,
    down,

    fn check(sym: Sym, pad: u32) bool {
        return pad & sym.code() != 0;
    }

    fn code(sym: Sym) u32 {
        return switch (sym) {
            .x => 1,
            .z => 2,
            .left => 16,
            .right => 32,
            .up => 64,
            .down => 128,
        };
    }
};

pub const Key = struct {
    x: bool,
    z: bool,
    left: bool,
    right: bool,
    up: bool,
    down: bool,
    old: u32,

    pub fn pressed(self: Key, sym: Sym) bool {
        const pre = new(self.old, 0);

        return switch (sym) {
            .x => self.x and !pre.x,
            .z => self.z and !pre.z,
            .left => self.left and !pre.left,
            .right => self.right and !pre.right,
            .up => self.up and !pre.up,
            .down => self.down and !pre.down,
        };
    }

    pub fn released(self: Key, sym: Sym) bool {
        const pre = new(self.old, 0);

        return switch (sym) {
            .x => !self.x and pre.x,
            .z => !self.z and pre.z,
            .left => !self.left and pre.left,
            .right => !self.right and pre.right,
            .up => !self.up and pre.up,
            .down => !self.down and pre.down,
        };
    }

    pub fn held(self: Key, sym: Sym) bool {
        const pre = new(self.old, 0);

        if (self.pressed(sym)) return true;

        return switch (sym) {
            .x => self.x and pre.x,
            .z => self.z and pre.z,
            .left => self.left and pre.left,
            .right => self.right and pre.right,
            .up => self.up and pre.up,
            .down => self.down and pre.down,
        };
    }

    fn new(pad: u32, old: u32) Key {
        return .{
            .x = Sym.check(.x, pad),
            .z = Sym.check(.z, pad),
            .left = Sym.check(.left, pad),
            .right = Sym.check(.right, pad),
            .up = Sym.check(.up, pad),
            .down = Sym.check(.down, pad),
            .old = old,
        };
    }
};

pub fn key(pad: u32, old: u32) Key {
    return Key.new(pad, old);
}

pub const Point = @Vector(2, i32);
pub const Size = @Vector(2, usize);

pub const rectArgs = struct {
    size: Size = .{ 1, 1 },
    color: RGB = .{ 255, 255, 255 },
};

pub const boxArgs = struct {
    size: Size = .{ 1, 1 },
    border: Size = .{ 1, 1 },
    color: RGB = .{ 0, 0, 0 },
    fill: bool = false,
    fillColor: RGB = .{ 0, 0, 0 },
};
