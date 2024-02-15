const std = @import("std");
const testing = std.testing;
const File = @import("file.zig").File;
const SparseTable = @import("sparse_table.zig").SparseTable;
const Allocator = std.mem.Allocator;

pub const LCA = struct {
    file_to_value_map: std.StringHashMap(u8),
    value_to_file_map: std.AutoHashMap(u8, *File),
    first_encounter: std.ArrayList(u8),
    sparse_table: *SparseTable,

    pub fn findParent(self: *LCA, first_file: *File, second_file: *File) ?*File {
        var first_val = self.file_to_value_map.get(first_file.path).?;
        var second_val = self.file_to_value_map.get(second_file.path).?;
        if (first_val > second_val) {
            const temp = first_val;
            first_val = second_val;
            second_val = temp;
        }
        const first_encounter_first = self.first_encounter.items[first_val];
        const first_encounter_second = self.first_encounter.items[second_val];

        const rs = self.sparse_table.rmq(first_encounter_first, first_encounter_second);
        return self.value_to_file_map.get(rs);
    }

    pub fn init(allocator: Allocator, root: *File) *LCA {
        const lca = allocator.create(LCA) catch @panic("error while creating LCA");
        var first_encounter = std.ArrayList(u8).initCapacity(allocator, 1000) catch @panic("error while creating first_encounter array");
        var file_to_value_map = std.StringHashMap(u8).init(allocator);
        var value_to_file_map = std.AutoHashMap(u8, *File).init(allocator);
        var index: u8 = 0;
        var count_file: u8 = 0;

        var euler_tour = std.ArrayList(u8).init(allocator);
        eulerTour(&euler_tour, root, &index, &count_file, &file_to_value_map, &value_to_file_map, &first_encounter) catch @panic("error while creating euler tour array");

        const rmq = SparseTable.init(allocator, euler_tour.items);
        lca.* = LCA{
            .file_to_value_map = file_to_value_map,
            .value_to_file_map = value_to_file_map,
            .first_encounter = first_encounter,
            .sparse_table = rmq,
        };

        return lca;
    }
};

fn eulerTour(euler_tour: *std.ArrayList(u8), root: *File, index: *u8, count_file: *u8, file_to_value_map: *std.StringHashMap(u8), value_to_file_map: *std.AutoHashMap(u8, *File), first_encounter: *std.ArrayList(u8)) !void {
    try file_to_value_map.put(root.path, count_file.*);
    try value_to_file_map.put(count_file.*, root);
    try euler_tour.append(count_file.*);
    try first_encounter.insert(count_file.*, index.*);
    index.* += 1;
    for (root.children.items) |child| {
        if (file_to_value_map.getKey(child.path) == null) {
            count_file.* += 1;
            try eulerTour(euler_tour, child, index, count_file, file_to_value_map, value_to_file_map, first_encounter);
            const toAppend = file_to_value_map.get(root.path).?;
            try euler_tour.append(toAppend);
            index.* += 1;
        }
    }
}
