const std = @import("std");
const rl = @import("raylib");

pub const OutOfRegionBehaviour = enum {
    stop,
    disappear,
    bounce,
};

pub const Body = struct {
    box: rl.Rectangle = undefined,
    color: rl.Color = rl.Color.white,

    width: f32,
    height: f32,
    initialPosition: rl.Vector2,

    workingRegion: rl.Rectangle = undefined,
    outOfRegionBehaviour: OutOfRegionBehaviour = OutOfRegionBehaviour.stop,

    initAccelerationVector: rl.Vector2 = rl.Vector2{ .x = 0, .y = 0 },
    accelerationVector: rl.Vector2 = undefined,
    accelerationShouldDecrease: bool = true,

    visible: bool = true,

    pub fn reset(self: *Body) void {
        self.box.x = self.initialPosition.x;
        self.box.y = self.initialPosition.y;
        self.box.width = self.width;
        self.box.height = self.height;

        self.accelerationVector = self.initAccelerationVector;
    }

    pub fn accelerate(self: *Body, direction: rl.Vector2) void {
        self.accelerationVector = self.accelerationVector.add(direction);
    }

    pub fn update(self: *Body) void {
        self.box.x += self.accelerationVector.x;
        self.box.y += self.accelerationVector.y;

        if (!self.isInWorkingRegion()) {
            self.handleBoxOutOfRegion();
        }

        self.decreaseAcceleration();
    }

    pub fn draw(self: *const Body) void {
        if (!self.visible) {
            return;
        }

        rl.drawRectangleLinesEx(self.box, 2.0, self.color);
    }

    pub fn collides(self: *const Body, body: *Body) bool {
        if (!body.visible) return false;

        return self.box.checkCollision(body.box);
    }

    fn handleBoxOutOfRegion(self: *Body) void {
        switch (self.outOfRegionBehaviour) {
            OutOfRegionBehaviour.disappear => self.disapper(),
            OutOfRegionBehaviour.bounce => self.bounce(),
            OutOfRegionBehaviour.stop => self.stop(),
        }
    }

    fn isInWorkingRegion(self: *const Body) bool {
        if (self.box.x <= self.workingRegion.x) {
            return false;
        }

        if (self.box.y <= self.workingRegion.y) {
            return false;
        }

        if (self.box.x + self.width >= self.workingRegion.x + self.workingRegion.width) {
            return false;
        }

        if (self.box.y + self.height >= self.workingRegion.y + self.workingRegion.height) {
            return false;
        }

        return true;
    }

    fn disapper(self: *Body) void {
        self.accelerationVector = rl.Vector2{ .x = 0, .y = 0 };
        self.visible = false;
    }

    fn bounce(self: *Body) void {
        if (self.box.x <= self.workingRegion.x) {
            self.box.x = self.workingRegion.x;
            self.accelerationVector.x *= -1;
        }

        if (self.box.y <= self.workingRegion.y) {
            self.box.y = self.workingRegion.y;
            self.accelerationVector.y *= -1;
        }

        if (self.box.x + self.width >= self.workingRegion.x + self.workingRegion.width) {
            self.box.x = self.workingRegion.x + self.workingRegion.width - self.width;
            self.accelerationVector.x *= -1;
        }

        if (self.box.y + self.height >= self.workingRegion.y + self.workingRegion.height) {
            self.box.y = self.workingRegion.y + self.workingRegion.height - self.height;
            self.accelerationVector.y *= -1;
        }
    }

    fn stop(self: *Body) void {
        if (self.box.x <= self.workingRegion.x) {
            self.box.x = self.workingRegion.x;
            self.accelerationVector.x = 0;
        }

        if (self.box.y <= self.workingRegion.y) {
            self.box.y = self.workingRegion.y;
            self.accelerationVector.y = 0;
        }

        if (self.box.x + self.width >= self.workingRegion.x + self.workingRegion.width) {
            self.box.x = self.workingRegion.x + self.workingRegion.width - self.width;
            self.accelerationVector.x = 0;
        }

        if (self.box.y + self.height >= self.workingRegion.y + self.workingRegion.height) {
            self.box.y = self.workingRegion.y + self.workingRegion.height - self.height;
            self.accelerationVector.y = 0;
        }
    }

    fn decreaseAcceleration(self: *Body) void {
        if (!self.accelerationShouldDecrease) {
            return;
        }

        if (self.accelerationVector.x != 0) {
            self.accelerationVector.x -= self.accelerationVector.x * 0.1;
        }

        if (self.accelerationVector.y != 0) {
            self.accelerationVector.y -= self.accelerationVector.y * 0.1;
        }
    }
};
