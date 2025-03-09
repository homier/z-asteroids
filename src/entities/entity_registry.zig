const std = @import("std");

pub fn EntityRegistry(comptime T: type) type {
    return struct {
        const Queue = std.TailQueue(T);
        const Iterator = struct {
            node: ?*Queue.Node,
            index: usize = 0,

            pub fn next(self: *Iterator) ?*Queue.Node {
                defer {
                    if (self.node != null) {
                        self.node = self.node.?.next;
                        self.index += 1;
                    }
                }

                return self.node;
            }
        };

        items: Queue = .{},

        allocator: std.mem.Allocator,

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{ .allocator = allocator };
        }

        pub fn add(self: *Self, entity: T) !void {
            var node = try self.allocator.create(Queue.Node);

            node.data = entity;
            self.items.append(node);
        }

        pub fn addFirst(self: *Self, entity: T) !void {
            var node = try self.allocator.create(Queue.Node);

            node.data = entity;
            self.items.prepend(node);
        }

        pub fn iter(self: *const Self) Iterator {
            return .{ .node = self.items.first };
        }

        pub fn remove(self: *Self, node: *Queue.Node) void {
            defer self.allocator.destroy(node);

            self.items.remove(node);
        }

        pub fn clear(self: *Self) void {
            while (self.items.popFirst()) |node| {
                self.allocator.destroy(node);
            }
        }

        pub fn deinit(self: *Self) void {
            self.clear();
        }
    };
}
