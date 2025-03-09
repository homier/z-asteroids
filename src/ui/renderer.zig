const entity_registry = @import("../entities/entity_registry.zig");

pub fn Renderer(comptime T: type, comptime renderFn: fn (debug: bool, entity: T, index: usize) void) type {
    const Registry = entity_registry.EntityRegistry(T);

    return struct {
        const Self = @This();

        debug: bool = false,

        pub fn init(debug: bool) Self {
            return .{ .debug = debug };
        }

        pub fn render(self: Self, registry: *const Registry) void {
            var iter = registry.iter();

            while (iter.next()) |node| {
                renderFn(self.debug, node.data, iter.index - 1);
            }
        }
    };
}
