const std = @import("std");
const rl = @import("raylib");

const entity_registry = @import("./entity_registry.zig");

const EDGE_SECTOR_RADIUS = std.math.pi / 2.7;

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

        pub fn magnitude(self: Level) f32 {
            return switch (self) {
                .SMALL => std.math.pi / 2.0,
                .MEDIUM => std.math.pi / 3.0,
                .LARGE => std.math.pi / 4.0,
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

    edges: std.ArrayList(Edge),
    level: Level,

    pub fn init(allocator: std.mem.Allocator, position: rl.Vector2, lvl: Level, rand: *const std.Random) Asteroid {
        return .{
            .position = position,
            .edges = generateEdges(allocator, rand, position, lvl.radius(), lvl.magnitude()),
            .level = lvl,
            .radius = lvl.radius(),
            .velocity = generateVelocity(rand, lvl.velocityRange()),
            .rotationDirection = rand.enumValue(RotationDirection),
        };
    }

    pub fn deinit(self: *Asteroid) void {
        self.edges.deinit();
    }

    fn generateEdges(
        allocator: std.mem.Allocator,
        rand: *const std.Random,
        centre: rl.Vector2,
        radius: f32,
        edgeMaxAngle: f32,
    ) std.ArrayList(Edge) {
        var edges = std.ArrayList(Edge).init(allocator);
        var angleSum: f32 = 0;
        var idx: usize = 0;

        while (angleSum < std.math.pi * 2) {
            var angle = rand.float(f32) * (angleSum + edgeMaxAngle - angleSum) + angleSum;
            if (angle >= std.math.pi * 2) {
                angle = std.math.pi * 2;
            }

            var edge: Edge = .{ .start = rl.Vector2.zero(), .end = rl.Vector2.zero() };

            if (idx == 0) {
                edge.start = getCirclePoint(centre, radius, 0);
            } else {
                edge.start = edges.items[idx - 1].end;
            }

            edge.end = getCirclePoint(centre, radius, angle);
            edges.append(edge) catch unreachable;

            idx += 1;
            angleSum = angle;
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

        for (self.edges.items) |*edge| {
            edge.start = self.rotatePoint(edge.start, cos, sin).add(self.velocity);
            edge.end = self.rotatePoint(edge.end, cos, sin).add(self.velocity);
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
