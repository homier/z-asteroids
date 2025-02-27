const rl = @import("raylib");

const Body = @import("./body.zig").Body;
const utils = @import("./utils.zig");

const width = 100;
const height = 20;
pub const speed = 2.5;

pub const Ship = struct {
    body: Body = undefined,

    pub fn init() Ship {
        var ship = Ship{
            .body = .{
                .width = width,
                .height = height,
                .initialPosition = initialPosition(),
                .workingRegion = workingRegion(),
            },
        };

        ship.body.reset();
        return ship;
    }

    pub fn reset(self: *Ship) void {
        self.body.reset();
    }

    pub fn accelerate(self: *Ship, x: f32, y: f32) void {
        self.body.accelerate(rl.Vector2{ .x = x, .y = y });
    }

    pub fn workingRegion() rl.Rectangle {
        return rl.Rectangle{
            .x = 0,
            .y = utils.screenHeight() / 4 * 3,
            .width = utils.screenWidth(),
            .height = utils.screenHeight() / 4,
        };
    }

    fn initialPosition() rl.Vector2 {
        const region = workingRegion();

        return rl.Vector2{
            .x = (region.x + region.width) / 2.0 - width / 2,
            .y = (region.y + region.height) / 2.0 - height / 2,
        };
    }
};
