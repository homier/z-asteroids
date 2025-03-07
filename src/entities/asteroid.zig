const std = @import("std");
const rl = @import("raylib");

const entity_registry = @import("./entity_registry.zig");

const ASTEROID_EDGE_MAX_COUNT: usize = 7;
const EDGE_SECTOR_RADIUS = std.math.pi * 2 / @as(f32, @floatFromInt(ASTEROID_EDGE_MAX_COUNT));

pub const AsteroidRegistry = entity_registry.EntityRegistry(Asteroid);

pub const Asteroid = struct {
    pub const Level = enum {
        SMALL,
        MEDIUM,
        LARGE,

        pub fn radius(self: Level) f32 {
            return switch (self) {
                .SMALL => 25,
                .MEDIUM => 50,
                .LARGE => 100,
            };
        }

        fn velocityRange(self: Level) [2]i8 {
            return switch (self) {
                .SMALL => .{ 1, 3 },
                .MEDIUM => .{ 1, 2 },
                .LARGE => .{ 0, 1 },
            };
        }

        pub fn separatesInto(self: Level) struct { level: Level, count: usize } {
            return switch (self) {
                .SMALL => .{ .level = .SMALL, .count = 0 },
                .MEDIUM => .{ .level = .SMALL, .count = 2 },
                .LARGE => .{ .level = .MEDIUM, .count = 3 },
            };
        }

        pub fn destructionPoints(self: Level) u32 {
            return switch (self) {
                .SMALL => 15,
                .MEDIUM => 10,
                .LARGE => 5,
            };
        }
    };

    const RotationDirection = enum(i8) {
        FORWARD = 1,
        BACKWARD = -1,
    };

    const Edge = struct {
        start: rl.Vector2 = .{ .x = 0, .y = 0 },
        end: rl.Vector2 = .{ .x = 0, .y = 0 },
    };

    position: rl.Vector2,
    radius: f32,
    velocity: rl.Vector2,
    rotationDirection: RotationDirection,

    edges: [ASTEROID_EDGE_MAX_COUNT]Edge,
    level: Level,

    pub fn init(position: rl.Vector2, lvl: Level, rand: *const std.Random) Asteroid {
        return .{
            .position = position,
            .edges = generateEdges(position, lvl.radius()),
            .level = lvl,
            .radius = lvl.radius(),
            .velocity = generateVelocity(rand, lvl.velocityRange()),
            .rotationDirection = rand.enumValue(RotationDirection),
        };
    }

    fn generateEdges(centre: rl.Vector2, radius: f32) [ASTEROID_EDGE_MAX_COUNT]Edge {
        var edges: [ASTEROID_EDGE_MAX_COUNT]Edge = std.mem.zeroes([ASTEROID_EDGE_MAX_COUNT]Edge);

        for (0..ASTEROID_EDGE_MAX_COUNT) |idx| {
            const angle = @as(f32, @floatFromInt(idx + 1)) * EDGE_SECTOR_RADIUS;

            if (idx == 0) {
                const sAngle = @as(f32, @floatFromInt(idx)) * EDGE_SECTOR_RADIUS;

                edges[idx].start = getCirclePoint(centre, radius, sAngle);
            } else {
                edges[idx].start = edges[idx - 1].end;
            }

            edges[idx].end = getCirclePoint(centre, radius, angle);
        }

        return edges;
    }

    fn getCirclePoint(centre: rl.Vector2, radius: f32, angle: f32) rl.Vector2 {
        return centre.add(.{ .x = radius * std.math.cos(angle), .y = radius * std.math.sin(angle) });
    }

    fn generateVelocity(rand: *const std.Random, range: [2]i8) rl.Vector2 {
        return .{
            .x = randomVelocity(rand, range[0], range[1]),
            .y = randomVelocity(rand, range[0], range[1]),
        };
    }

    fn randomVelocity(rand: *const std.Random, min: i8, max: i8) f32 {
        const direction = @as(f32, @floatFromInt(@intFromEnum(rand.enumValue(RotationDirection))));
        const speed = @as(f32, @floatFromInt(rand.intRangeAtMost(i8, min, max))) + rand.float(f32);

        return direction * speed;
    }

    pub fn update(self: *Asteroid) void {
        const angle = std.math.degreesToRadians(@as(f32, @floatFromInt(@intFromEnum(self.rotationDirection))));

        const sin = std.math.sin(angle);
        const cos = std.math.cos(angle);

        self.position = self.position.add(self.velocity);

        for (0..ASTEROID_EDGE_MAX_COUNT) |idx| {
            self.edges[idx].start = self.rotatePoint(self.edges[idx].start, cos, sin).add(self.velocity);
            self.edges[idx].end = self.rotatePoint(self.edges[idx].end, cos, sin).add(self.velocity);
        }
    }

    fn rotatePoint(self: *const Asteroid, point: rl.Vector2, cos: f32, sin: f32) rl.Vector2 {
        return .{
            .x = ((point.x - self.position.x) * cos) - ((self.position.y - point.y) * sin) + self.position.x,
            .y = self.position.y - ((self.position.y - point.y) * cos) - ((point.x - self.position.x) * sin),
        };
    }

    pub fn isVisible(self: *const Asteroid, area: rl.Rectangle) bool {
        return self.getBbox().checkCollision(area);
    }

    pub fn getBbox(self: *const Asteroid) rl.Rectangle {
        return rl.Rectangle.init(
            self.position.x - self.radius,
            self.position.y - self.radius,
            self.radius * 2,
            self.radius * 2,
        );
    }

    pub fn collides(self: *const Asteroid, object: rl.Rectangle) bool {
        return object.checkCollision(self.getBbox());
    }
};
