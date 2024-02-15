const std = @import("std");
const Allocator = std.mem.Allocator;

pub const SparseTable = struct {
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
                if (input[sparse[i][j - 1]] < input[sparse[m][j - 1]]) {
                    sparse[i][j] = sparse[i][j - 1];
                } else {
                    sparse[i][j] = sparse[m][j - 1];
                }
            }
            to = std.math.pow(u8, 2, j + 1);
        }
        return sparse;
    }

    pub fn rmq(self: *SparseTable, low: u8, high: u8) u8 {
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

test "preprocessing" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var arr = [_]u8{ 4, 6, 1, 5, 7, 3 };
    const sparse_table = SparseTable.init(allocator, &arr);

    var expected_first_row = [_]u8{ 0, 0, 2 };
    var expected_second_row = [_]u8{ 1, 2, 2 };
    var expected_third_row = [_]u8{ 2, 2, 2 };
    var expected_fourth_row = [_]u8{ 3, 3, 170 };
    var expected_fifth_row = [_]u8{ 4, 5, 170 };
    var expected_sixth_row = [_]u8{ 5, 170, 170 };

    var expected_sparse_table = [_][]u8{
        &expected_first_row,
        &expected_second_row,
        &expected_third_row,
        &expected_fourth_row,
        &expected_fifth_row,
        &expected_sixth_row,
    };

    for (&expected_sparse_table, 0..) |e, i| {
        try std.testing.expectEqualSlices(u8, sparse_table.sparse_table[i], e);
    }
}
