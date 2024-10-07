const std = @import("std");

pub fn build(b: *std.Build) void {
    _ = b.addModule("art", .{
        .root_source_file = b.path("src/art.zig"),
    });
}
