const std = @import("std");
const Allocator = std.mem.Allocator;
const File = @import("file.zig").File;
const LCA = @import("lca.zig").LCA;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const root = File.init(allocator, "root");
    const a = File.init(allocator, "a");
    const b = File.init(allocator, "b");
    const c = File.init(allocator, "c");
    const d = File.init(allocator, "d");

    try root.addChild(a);
    try root.addChild(b);

    try a.addChild(c);
    try a.addChild(d);

    const lca = LCA.init(allocator, root);
    const lowest_common_parent = lca.findParent(a, b) catch |err| {
        std.debug.print("x Something went wrong!\n", .{});
        return err;
    };

    if (lowest_common_parent) |lowest| {
        std.debug.print("Found lowest: {s}", .{lowest.path});
    }
}
