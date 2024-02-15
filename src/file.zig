const std = @import("std");
const Allocator = std.mem.Allocator;

pub const File = struct {
    path: []const u8,
    children: std.ArrayList(*File),

    pub fn addChild(self: *File, children: *File) !void {
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
