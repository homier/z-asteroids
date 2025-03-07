const entity_registry = @import("../entities/entity_registry.zig");

pub fn Drawer(comptime T: type, comptime drawFn: fn (debug: bool, entity: T) void) type {
    const Registry = entity_registry.EntityRegistry(T);

    return struct {
        const Self = @This();

        debug: bool = false,

        pub fn init(debug: bool) Self {
            return .{ .debug = debug };
        }

        pub fn draw(self: Self, registry: *const Registry) void {
            var iter = registry.iter();

            while (iter.next()) |node| {
                drawFn(self.debug, node.data);
            }
        }
    };
}
