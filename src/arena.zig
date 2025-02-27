const std = @import("std");
const rl = @import("raylib");

const shipl = @import("./ship.zig");
const starl = @import("./star.zig");
const utils = @import("./utils.zig");

const initialStarsConut = 5;

pub const Arena = struct {
    ship: shipl.Ship = undefined,
    stars: std.ArrayList(starl.Star),

    rand: *const std.Random,

    playerScore: u32 = 0,
    starsAlive: usize = 0,

    backgroundSound: rl.Sound,

    pub fn init(rand: *const std.Random, backgroundSound: rl.Sound) Arena {
        return Arena{
            .ship = shipl.Ship.init(),
            .stars = std.ArrayList(starl.Star).init(std.heap.page_allocator),
            .rand = rand,
            .backgroundSound = backgroundSound,
        };
    }

    pub fn loop(self: *Arena) !void {
        defer self.stars.deinit();
        rl.playSound(self.backgroundSound);

        while (!rl.windowShouldClose()) {
            if (!rl.isSoundPlaying(self.backgroundSound)) {
                rl.playSound(self.backgroundSound);
            }

            self.handleInput();
            try self.update();

            rl.beginDrawing();
            defer rl.endDrawing();

            rl.clearBackground(rl.Color.black);

            self.drawObjects();
        }
    }

    fn handleInput(self: *Arena) void {
        if (rl.isKeyDown(.right) or rl.isKeyDown(.d)) {
            self.ship.accelerate(shipl.speed, 0);
        }

        if (rl.isKeyDown(.left) or rl.isKeyDown(.a)) {
            self.ship.accelerate(-shipl.speed, 0);
        }

        if (rl.isKeyDown(.up) or rl.isKeyDown(.w)) {
            self.ship.accelerate(0, -shipl.speed);
        }

        if (rl.isKeyDown(.down) or rl.isKeyDown(.s)) {
            self.ship.accelerate(0, shipl.speed);
        }

        if (rl.isKeyDown(.enter)) {
            self.playerScore = 0;
            self.starsAlive = 0;
            self.ship.reset();
        }
    }

    fn update(self: *Arena) !void {
        self.ship.body.update();

        if (self.starsAlive == 0) {
            try self.generateStars();
        }

        self.checkShipCatches();
    }

    fn generateStars(self: *Arena) !void {
        if (self.playerScore == 0) {
            return self.generateInitialStars();
        }

        for (self.stars.items) |*star| {
            star.shuffle(self.rand);
        }

        for (0..@divTrunc(self.playerScore, 4)) |_| {
            try self.stars.append(starl.Star.init(self.rand));
        }

        self.starsAlive = self.stars.items.len;
    }

    fn generateInitialStars(self: *Arena) !void {
        self.stars.clearAndFree();

        for (0..initialStarsConut) |_| {
            try self.stars.append(starl.Star.init(self.rand));
        }

        self.starsAlive = 5;
        return;
    }

    fn checkShipCatches(self: *Arena) void {
        for (self.stars.items) |*star| {
            if (self.ship.body.collides(&star.body)) {
                self.playerScore += 1;
                self.starsAlive -= 1;

                star.body.visible = false;
                continue;
            }

            star.body.update();
        }
    }

    fn drawObjects(self: *Arena) void {
        drawScore(self.playerScore);
        drawFPS();
        drawWorkingRegionSeparator();

        self.ship.body.draw();

        for (self.stars.items) |*star| {
            star.body.draw();
        }
    }

    fn drawScore(score: u32) void {
        rl.drawText(
            rl.textFormat("Player score: %i", .{score}),
            10,
            10,
            20,
            rl.Color.yellow,
        );
    }

    fn drawFPS() void {
        rl.drawText(rl.textFormat("FPS: %i", .{rl.getFPS()}), 10, 35, 10, rl.Color.green);
    }

    fn drawWorkingRegionSeparator() void {
        const region = shipl.Ship.workingRegion();

        rl.drawLineEx(rl.Vector2{ .x = -5, .y = region.y }, rl.Vector2{
            .x = region.width + 5,
            .y = region.y,
        }, 1, rl.Color.dark_gray);
    }
};
