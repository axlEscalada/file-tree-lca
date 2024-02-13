const std = @import("std");
const Allocator = std.mem.Allocator;

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

    const lowest_common_parent = findParent(allocator, root, a, b);
    if (lowest_common_parent) |lowest| {
        std.debug.print("Found lowest: {s}", .{lowest.path});
    }
}

const File = struct {
    path: []const u8,
    children: std.ArrayList(*File),

    fn addChild(self: *File, children: *File) !void {
        try self.children.append(children);
    }

    pub fn init(alloc: std.mem.Allocator, path: []const u8) *File {
        const file = alloc.create(File) catch @panic("can't allocate file");
        file.* = File{
            .path = path,
            .children = std.ArrayList(*File).init(alloc),
        };
        return file;
    }
};

var file_to_value_map: std.StringHashMap(u8) = undefined;
var value_to_file_map: std.AutoHashMap(u8, *File) = undefined;
const max = 100;
var euler_tour = [_][]const u8{""} ** max;
var index: u8 = 0;
var countFile: u8 = 0;

fn findParent(allocator: std.mem.Allocator, root: *File, first_file: *File, second_file: *File) ?*File {
    file_to_value_map = std.StringHashMap(u8).init(allocator);
    value_to_file_map = std.AutoHashMap(u8, *File).init(allocator);
    eulerTour(root) catch @panic("error while walking tree");

    return findLowestFor(first_file, second_file);
}

//This algorithm will iterate over the euler tour array when it finds one of the files it will store
//the lowest common ancestor using the count file value until it finds the second file it will break
//and return the lowest between those two indexes;
fn findLowestFor(first: *File, second: *File) ?*File {
    const first_idx = file_to_value_map.get(first.path);
    const second_idx = file_to_value_map.get(second.path);

    var lowest: u8 = 255;
    var to_find: u8 = 0;

    const j = blk: {
        for (0.., euler_tour) |i, e| {
            const idx = file_to_value_map.get(e).?;
            if (idx == first_idx or idx == second_idx) {
                to_find = if (idx == first_idx.?) second_idx.? else first_idx.?;
                break :blk i;
            }
        }
        break :blk 0;
    };

    for (j..euler_tour.len) |i| {
        const e = euler_tour[i];
        const idx = file_to_value_map.get(e).?;

        if (idx == to_find) {
            if (idx < lowest) {
                lowest = idx;
            }
            break;
        } else {
            if (idx < lowest) {
                lowest = idx;
            }
        }
    }

    return value_to_file_map.get(lowest);
}

// Will iterate all the file tree saving in a map the visited files with the path as key and count file as a value, this countfile will increase only for new files in the tree. In the eulen_tour array is storead all the walkthrough so with this array we can find the lowest common anceestor between tho files.
fn eulerTour(root: *File) !void {
    try file_to_value_map.put(root.path, countFile);
    try value_to_file_map.put(countFile, root);
    euler_tour[index] = root.path;
    index += 1;
    for (root.children.items) |child| {
        if (file_to_value_map.getKey(child.path) == null) {
            countFile += 1;
            try eulerTour(child);
            euler_tour[index] = root.path;
            index += 1;
        }
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
    const lowest_common_parent = findParent(allocator, root, d, f);

    try std.testing.expectEqualStrings("a", lowest_common_parent.?.path);
}
