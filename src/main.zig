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
    const lowest_common_parent = lca.findParent(a, b);
    if (lowest_common_parent) |lowest| {
        std.debug.print("Found lowest: {s}", .{lowest.path});
    }
}

//          root
//          a ---> LCA
//      b       c
//  d <             e
//                      f <
test "find complex nested file tree" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const root = File.init(allocator, "root");
    const a = File.init(allocator, "a");
    const b = File.init(allocator, "b");
    const c = File.init(allocator, "c");
    const d = File.init(allocator, "d");
    const e = File.init(allocator, "e");
    const f = File.init(allocator, "f");

    try root.addChild(a);

    try a.addChild(b);
    try a.addChild(c);

    try b.addChild(d);
    try c.addChild(e);
    try e.addChild(f);
    const lca = LCA.init(allocator, root);
    const lowest_common_parent = lca.findParent(d, f);

    try std.testing.expectEqualStrings("a", lowest_common_parent.?.path);
}

test "should find the common file for each find call" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const root = File.init(allocator, "root");
    const a = File.init(allocator, "a");
    const b = File.init(allocator, "b");
    const c = File.init(allocator, "c");
    const d = File.init(allocator, "d");
    const e = File.init(allocator, "e");
    const f = File.init(allocator, "f");
    const g = File.init(allocator, "g");
    const h = File.init(allocator, "h");
    const i = File.init(allocator, "i");
    const j = File.init(allocator, "j");
    const k = File.init(allocator, "k");

    try root.addChild(a);
    try root.addChild(b);

    try a.addChild(c);
    try a.addChild(d);

    try b.addChild(i);
    try b.addChild(j);

    try c.addChild(e);
    try c.addChild(f);

    try d.addChild(g);
    try d.addChild(h);

    try i.addChild(k);

    const lca = LCA.init(allocator, root);

    const lca_d_f = lca.findParent(d, f);
    const lca_e_f = lca.findParent(e, f);
    const lca_k_h = lca.findParent(k, h);

    try std.testing.expectEqualStrings("a", lca_d_f.?.path);
    try std.testing.expectEqualStrings("c", lca_e_f.?.path);
    try std.testing.expectEqualStrings("root", lca_k_h.?.path);
}

test "find simple nested file tree" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const root = File.init(allocator, "root");
    const a = File.init(allocator, "a");
    const b = File.init(allocator, "b");

    try root.addChild(a);
    try root.addChild(b);

    const lca = LCA.init(allocator, root);
    const lowest_common_parent = lca.findParent(a, b);

    try std.testing.expectEqualStrings("root", lowest_common_parent.?.path);
}

// test "preprocessing" {
//     var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
//     defer arena.deinit();

//     const allocator = arena.allocator();

//     var arr = [_]u8{ 3, 1, 2, 6, 5, 1 };
//     preprocess(allocator, &arr, arr.len) catch @panic("error prepo");

//     std.debug.print("sparse_table {s}", .{sparse_table});
// }
