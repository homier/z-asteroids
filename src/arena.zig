const std = @import("std");
const rl = @import("raylib");

const utils = @import("./utils.zig");

const asteroid = @import("./entities/asteroid.zig");
const player = @import("./entities/player.zig");
const projectile = @import("./entities/projectile.zig");

const arena_drawer = @import("./ui/arena.zig");

const sound_resources = @import("./resources/sounds.zig");

const SHOOTING_THROTTLE_DURATION = 200; // 0.2 sec
const ASTEROIDS_MIN_COUNT = 5;

pub const Arena = struct {
    allocator: std.mem.Allocator,
    rand: *const std.Random,

    player: player.Player = undefined,
    asteroids: asteroid.AsteroidRegistry,
    projectiles: projectile.ProjectileRegistry,

    lastShootAt: i64 = 0,

    drawer: arena_drawer.ArenaDrawer,

    playerScore: u32 = 0,
    playerLifes: u8 = 5,

    screen: rl.Rectangle,
    sounds: sound_resources.Sounds,

    pub fn init(
        allocator: std.mem.Allocator,
        rand: *const std.Random,
        sounds: sound_resources.Sounds,
    ) !Arena {
        return .{
            .allocator = allocator,
            .rand = rand,

            .player = player.Player.init(utils.screenMiddle()),
            .projectiles = projectile.ProjectileRegistry.init(allocator),
            .asteroids = asteroid.AsteroidRegistry.init(allocator),

            .drawer = try arena_drawer.ArenaDrawer.init(false),

            .screen = utils.screenRectangle(),
            .sounds = sounds,
        };
    }

    pub fn deinit(self: *Arena) void {
        self.asteroids.deinit();
        self.projectiles.deinit();
    }

    pub fn update(self: *Arena) void {
        self.screen = utils.screenRectangle();

        self.updateProjectiles();
        self.updateAsteroids();
        self.updatePlayer();
    }

    pub fn addAsteroid(self: *Arena, position: rl.Vector2, level: asteroid.Asteroid.Level) !void {
        const a = asteroid.Asteroid.init(position, level, self.rand);

        try self.asteroids.add(a);
    }

    pub fn handleInput(self: *Arena) !void {
        if (rl.isKeyDown(.right) or rl.isKeyDown(.d)) {
            self.player.rotate(2);
        }

        if (rl.isKeyDown(.left) or rl.isKeyDown(.a)) {
            self.player.rotate(-2);
        }

        if (rl.isKeyDown(.up) or rl.isKeyDown(.w)) {
            self.player.accelerate(0, -0.5);
        }

        if (rl.isKeyDown(.down) or rl.isKeyDown(.s)) {
            self.player.accelerate(0, 0.5);
        }

        if (rl.isKeyDown(.space)) {
            try self.shoot();
        }
    }

    fn shoot(self: *Arena) !void {
        const ts = std.time.milliTimestamp();

        if (ts - self.lastShootAt < SHOOTING_THROTTLE_DURATION) {
            return;
        }

        try self.projectiles.add(
            projectile.Projectile.init(
                self.player.position,
                self.player.velocity,
                self.player.rotation,
            ),
        );

        self.lastShootAt = ts;

        rl.playSound(self.sounds.fire);
    }

    fn updateProjectiles(self: *Arena) void {
        var iter = self.projectiles.iter();

        while (iter.next()) |node| {
            node.data.update();

            if (!node.data.isVisible(self.screen)) {
                self.projectiles.remove(node);
                std.log.debug("arena: updateProjectiles: removed projectile", .{});

                continue;
            }

            if (self.checkProjectileCollision(&node.data) catch true) {
                std.log.debug("arena: updateProjectiles: projectile collided with asteroid, removed", .{});
                self.projectiles.remove(node);
            }
        }
    }

    fn updateAsteroids(self: *Arena) void {
        if (self.asteroids.items.len < ASTEROIDS_MIN_COUNT) {
            for (self.asteroids.items.len..ASTEROIDS_MIN_COUNT) |_| {
                const a = self.generateRandomAsteroid();

                self.asteroids.add(a) catch unreachable;
            }
        }

        var iter = self.asteroids.iter();

        while (iter.next()) |node| {
            node.data.update();

            if (!node.data.isVisible(self.screen)) {
                self.asteroids.remove(node);

                std.log.debug("arena: updateAsteroids: removed asteroid", .{});
            }
        }
    }

    fn generateRandomAsteroid(self: *Arena) asteroid.Asteroid {
        const randomHeight = self.rand.boolean();
        const level = self.rand.enumValue(asteroid.Asteroid.Level);

        var position: rl.Vector2 = .{ .x = 0, .y = 0 };

        if (randomHeight) {
            position.y = @as(f32, @floatFromInt(self.rand.intRangeAtMost(i32, 0, rl.getScreenHeight())));
            position.x = -level.radius() + 1;
        } else {
            position.x = @as(f32, @floatFromInt(self.rand.intRangeAtMost(i32, 0, rl.getScreenWidth())));
            position.y = -level.radius() + 1;
        }

        return asteroid.Asteroid.init(position, level, self.rand);
    }

    fn checkProjectileCollision(self: *Arena, p: *const projectile.Projectile) !bool {
        const bbox = p.getBbox();

        var iter = self.asteroids.iter();
        while (iter.next()) |node| {
            if (!node.data.isVisible(self.screen)) {
                continue;
            }

            if (node.data.collides(bbox)) {
                try self.handleProjectileHit(&node.data);

                self.asteroids.remove(node);
                return true;
            }
        }

        return false;
    }

    fn handleProjectileHit(self: *Arena, a: *const asteroid.Asteroid) !void {
        self.playerScore += a.level.destructionPoints();

        switch (a.level) {
            .SMALL => rl.playSound(self.sounds.bang_small),
            .MEDIUM => rl.playSound(self.sounds.bang_medium),
            .LARGE => rl.playSound(self.sounds.bang_large),
        }

        const separatesIn = a.level.separatesInto();

        for (0..separatesIn.count) |_| {
            try self.addAsteroid(a.position, separatesIn.level);
        }
    }

    fn updatePlayer(self: *Arena) void {
        self.player.update();
    }

    pub fn draw(self: *Arena) void {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        drawScore(self.playerScore);
        drawPlayerLifes(self.playerLifes);
        // drawFPS();

        self.drawer.draw(&self.player, &self.projectiles, &self.asteroids);
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

    fn drawPlayerLifes(lifes: u32) void {
        rl.drawText(rl.textFormat("Lifes: %i", .{lifes}), 10, 35, 20, rl.Color.green);
    }

    fn drawFPS() void {
        rl.drawText(rl.textFormat("FPS: %i", .{rl.getFPS()}), 10, 35, 10, rl.Color.green);
    }
};
