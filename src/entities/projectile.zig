const std = @import("std");
const rl = @import("raylib");

const entity_registry = @import("entity_registry.zig");

const RADIUS = 2;
const VELOCITY = rl.Vector2{ .x = 0, .y = -10 };

pub const ProjectileRegistry = entity_registry.EntityRegistry(Projectile);

pub const Projectile = struct {
    position: rl.Vector2,
    radius: f32 = RADIUS,
    velocity: rl.Vector2,
    shootAt: i64,

    pub fn init(position: rl.Vector2, _: rl.Vector2, angle: f32) Projectile {
        return .{
            .position = position,
            .velocity = VELOCITY.rotate(std.math.degreesToRadians(angle)),
            .shootAt = std.time.milliTimestamp(),
        };
    }

    pub fn update(self: *Projectile) void {
        self.position = self.position.add(self.velocity);
    }

    pub fn getBbox(self: *const Projectile) rl.Rectangle {
        return .{
            .x = self.position.x - RADIUS,
            .y = self.position.y - RADIUS,
            .width = RADIUS * 2,
            .height = RADIUS * 2,
        };
    }

    pub fn isVisible(self: *const Projectile, visibleArea: rl.Rectangle) bool {
        if (self.position.x < visibleArea.x) return false;
        if (self.position.x > visibleArea.x + visibleArea.width) return false;
        if (self.position.y < visibleArea.y) return false;
        if (self.position.y > visibleArea.y + visibleArea.height) return false;

        return true;
    }
};
