const std = @import("std");

const rl = @import("raylib");
const state = @import("./player_state.zig");
const utils = @import("./../utils.zig");

const TEXTURE_BOX = rl.Rectangle.init(0, 0, 128, 128);
const RADIUS = 24;
const WIDTH = RADIUS * 3;
const HEIGHT = RADIUS * 3;

const VELOCITY_SCALING_FACTOR = 0.01;
const VELOCITY_MIN = 0.2;

pub const Player = struct {
    position: rl.Vector2,
    width: f32 = WIDTH,
    height: f32 = HEIGHT,

    bbox: rl.Rectangle,
    velocity: rl.Vector2 = rl.Vector2{ .x = 0, .y = 0 },
    rotation: f32 = 0,
    state: state.PlayerState = state.PlayerState.DEFAULT,

    pub fn init(position: rl.Vector2) Player {
        return .{
            .position = position,
            .bbox = rl.Rectangle.init(
                position.x - WIDTH / 2,
                position.y - HEIGHT / 2,
                WIDTH,
                HEIGHT,
            ),
        };
    }

    pub fn update(self: *Player) void {
        self.updatePosition();
        self.updateBbox();
        self.updateVelocity();
    }

    pub fn accelerate(self: *Player, x: f32, y: f32) void {
        self.velocity = self.velocity.add(rl.Vector2{ .x = x, .y = y });
    }

    pub fn rotate(self: *Player, angle: f32) void {
        self.rotation += angle;
    }

    pub fn getActualVelocity(self: *const Player) rl.Vector2 {
        return self.velocity.rotate(std.math.degreesToRadians(self.rotation));
    }

    fn updatePosition(self: *Player) void {
        const angularVelocity = self.velocity.rotate(std.math.degreesToRadians(self.rotation));

        self.position = self.position.add(angularVelocity);

        if (self.position.x < 0) {
            self.position.x = utils.screenWidth();
        }

        if (self.position.x > utils.screenWidth()) {
            self.position.x = 0;
        }

        if (self.position.y < 0) {
            self.position.y = utils.screenHeight();
        }

        if (self.position.y > utils.screenHeight()) {
            self.position.y = 0;
        }
    }

    fn updateBbox(self: *Player) void {
        self.bbox.x = self.position.x - self.width / 2;
        self.bbox.y = self.position.y - self.height / 2;
    }

    fn updateVelocity(self: *Player) void {
        var delta = rl.Vector2.zero();

        if (self.velocity.x != 0) {
            delta.x = self.velocity.x * VELOCITY_SCALING_FACTOR;
        }

        if (self.velocity.y != 0) {
            delta.y = self.velocity.y * VELOCITY_SCALING_FACTOR;
        }

        self.velocity = self.velocity.subtract(delta);

        if (@abs(self.velocity.x) < VELOCITY_MIN) {
            self.velocity.x = 0;
        }

        if (@abs(self.velocity.y) < VELOCITY_MIN) {
            self.velocity.y = 0;
        }
    }
};
