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
                sparse[i][j] = @min(input[sparse[i][j - 1]], input[sparse[m][j - 1]]);
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
