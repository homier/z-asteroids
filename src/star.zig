const std = @import("std");
const rl = @import("raylib");

const body = @import("./body.zig");
const utils = @import("./utils.zig");

const size = 4;
const speed = 7;

pub const Star = struct {
    body: body.Body = undefined,

    pub fn init(rand: *const std.Random) Star {
        var star = Star{
            .body = .{
                .color = rl.Color.gold,
                .width = size,
                .height = size,
                .initialPosition = initialPosition(rand),
                .workingRegion = utils.screenRectangle(),
                .outOfRegionBehaviour = body.OutOfRegionBehaviour.bounce,
                .accelerationShouldDecrease = false,
                .initAccelerationVector = initialAccelerationVector(rand),
            },
        };

        star.body.reset();
        return star;
    }

    fn initialAccelerationVector(rand: *const std.Random) rl.Vector2 {
        return rl.Vector2{
            .x = @as(f32, @floatFromInt(rand.intRangeAtMost(i32, -2, 2))) + rand.floatExp(f32),
            .y = @as(f32, @floatFromInt(rand.intRangeAtMost(i32, 2, speed))) + rand.floatExp(f32),
        };
    }

    fn initialPosition(rand: *const std.Random) rl.Vector2 {
        return rl.Vector2{
            .x = @as(f32, @floatFromInt(rand.intRangeAtMost(i32, 0, rl.getScreenWidth()))),
            .y = 0,
        };
    }

    pub fn shuffle(self: *Star, rand: *const std.Random) void {
        self.body.initialPosition = initialPosition(rand);
        self.body.initAccelerationVector = initialAccelerationVector(rand);

        self.body.visible = true;
        self.body.reset();
    }
};
