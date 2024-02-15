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

    const lca = LCA.init(allocator, root);
    const lowest_common_parent = lca.findParent(allocator, a, b);
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

    pub fn init(alloc: Allocator, path: []const u8) *File {
        const file = alloc.create(File) catch @panic("can't allocate file");
        file.* = File{
            .path = path,
            .children = std.ArrayList(*File).init(alloc),
        };
        return file;
    }
};

const SparseTable = struct {
    sparse_table: [][]u8,
    input: []u8,

    fn preprocess(allocator: Allocator, input: []u8, n: usize) ![][]u8 {
        var sparse = try allocator.alloc([]u8, n);
        const k = std.math.log2(n) + 1;
        for (0..n) |r| {
            const i: u8 = @intCast(r);
            sparse[i] = try allocator.alloc(u8, k);
            sparse[i][0] = i;
        }

        var to: u8 = 2;
        var j: u8 = 1;
        while (to <= n) : (j += 1) {
            var i: u8 = 0;
            while (i + to - 1 < n) : (i += 1) {
                const m = i + std.math.pow(u8, 2, j - 1);
                sparse[i][j] = @min(input[sparse[i][j - 1]], input[sparse[m][j - 1]]);
            }
            to = std.math.pow(u8, 2, j + 1);
        }
        return sparse;
    }

    fn rmq(self: *SparseTable, low: u8, high: u8) u8 {
        const l = high - low + 1;
        const k = std.math.log2(l);
        const to = std.math.pow(u8, 2, k);

        if (self.input[self.sparse_table[low][k]] <= self.input[self.sparse_table[low + l - to][k]]) {
            return self.input[self.sparse_table[low][k]];
        }
        return self.input[self.sparse_table[high - to + 1][k]];
    }

    pub fn init(allocator: Allocator, input: []u8) *SparseTable {
        const len = input.len;
        const sparse = SparseTable.preprocess(allocator, input, len) catch @panic("error while preprocessing the sparse table for rmq");

        const rangeMinimumQueue = allocator.create(SparseTable) catch @panic("can't allocate SparseTable");
        rangeMinimumQueue.* = SparseTable{
            .sparse_table = sparse,
            .input = input,
        };
        return rangeMinimumQueue;
    }
};

const LCA = struct {
    file_to_value_map: std.StringHashMap(u8),
    value_to_file_map: std.AutoHashMap(u8, *File),
    euler_tour: std.ArrayList(u8),
    first_encounter: std.ArrayList(u8),
    index: u8,
    countFile: u8,
    sparse_table: *SparseTable,

    fn findParent(self: *LCA, allocator: Allocator, first_file: *File, second_file: *File) ?*File {
        var first_val = self.file_to_value_map.get(first_file.path).?;
        var second_val = self.file_to_value_map.get(second_file.path).?;
        if (first_val > second_val) {
            const temp = first_val;
            first_val = second_val;
            second_val = temp;
        }
        const first_encounter_first = self.first_encounter.items[first_val];
        const first_encounter_second = self.first_encounter.items[second_val];

        const rs = rmq.rmq(first_encounter_first, first_encounter_second);
        return self.value_to_file_map.get(rs);
    }

    // Will iterate all the file tree saving in a map the visited files with the path as key and count file as a value, this countfile will increase only for new files in the tree. In the eulen_tour array is storead all the walkthrough so with this array we can find the lowest common anceestor between tho files.
    fn eulerTour(self: *LCA, root: *File) !void {
        try self.file_to_value_map.put(root.path, self.countFile);
        try self.value_to_file_map.put(self.countFile, root);
        try self.euler_tour.append(self.countFile);
        try self.first_encounter.insert(self.countFile, self.index);
        self.index += 1;
        for (root.children.items) |child| {
            if (self.file_to_value_map.getKey(child.path) == null) {
                self.countFile += 1;
                try self.eulerTour(child);
                const toAppend = self.file_to_value_map.get(root.path).?;
                try self.euler_tour.append(toAppend);
                self.index += 1;
            }
        }
    }

    pub fn init(allocator: Allocator, root: *File) *LCA {
        const lca = allocator.create(LCA) catch @panic("error while creating LCA");
        const first_encounter = std.ArrayList(u8).initCapacity(allocator, 1000) catch @panic("error while creating first_encounter array");

        lca.* = LCA{
            .file_to_value_map = std.StringHashMap(u8).init(allocator),
            .value_to_file_map = std.AutoHashMap(u8, *File).init(allocator),
            .euler_tour = std.ArrayList(u8).init(allocator),
            .first_encounter = first_encounter,
            .index = 0,
            .countFile = 0,
        };
        lca.eulerTour(root) catch @panic("error while walking tree");
        const rmq = SparseTable.init(allocator, self.euler_tour.items);

        return lca;
    }
};

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
    const lowest_common_parent = lca.findParent(allocator, d, f);

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

    const lca_d_f = lca.findParent(allocator, d, f);
    const lca_e_f = lca.findParent(allocator, e, f);
    const lca_k_h = lca.findParent(allocator, k, h);

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
    const lowest_common_parent = lca.findParent(allocator, a, b);

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
