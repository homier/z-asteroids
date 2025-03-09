const std = @import("std");
const rl = @import("raylib");

const utils = @import("./utils.zig");

const asteroid = @import("./entities/asteroid.zig");
const player = @import("./entities/player.zig");
const projectile = @import("./entities/projectile.zig");
const notification = @import("./entities/notification.zig");

const arena_renderer = @import("./ui/arena.zig");

const sound_resources = @import("./resources/sounds.zig");

const SHOOTING_THROTTLE_DURATION = 200; // 0.2 sec
const ASTEROIDS_MIN_COUNT = 8;
const POINTS_PER_NEW_ASTEROID = 200;
const PLAYER_LIFES_AMOUNT = 5;

pub const Arena = struct {
    allocator: std.mem.Allocator,
    rand: *const std.Random,

    player: player.Player = undefined,
    asteroids: asteroid.AsteroidRegistry,
    projectiles: projectile.ProjectileRegistry,
    notifications: notification.NotificationRegistry,

    lastShootAt: i64 = 0,

    renderer: arena_renderer.ArenaRenderer,

    playerScore: u32 = 0,
    playerLifes: u8 = PLAYER_LIFES_AMOUNT,

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
            .notifications = notification.NotificationRegistry.init(allocator),

            .renderer = try arena_renderer.ArenaRenderer.init(false, PLAYER_LIFES_AMOUNT),

            .screen = utils.screenRectangle(),
            .sounds = sounds,
        };
    }

    pub fn deinit(self: *Arena) void {
        self.asteroids.deinit();
        self.projectiles.deinit();
        self.notifications.deinit();
    }

    pub fn reset(self: *Arena) void {
        self.playerLifes = PLAYER_LIFES_AMOUNT;
        self.playerScore = 0;
        self.player.reset();

        self.projectiles.clear();
        self.asteroids.clear();
        self.notifications.clear();
    }

    pub fn update(self: *Arena) void {
        if (self.playerLifes > 0) {
            self.screen = utils.screenRectangle();

            self.updateProjectiles();
            self.updateAsteroids();
            self.updatePlayer();
        }

        self.updateNotifications();
    }

    pub fn render(self: *Arena) void {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        self.renderer.render(
            &self.player,
            &self.projectiles,
            &self.asteroids,
            &self.notifications,
            self.playerScore,
            self.playerLifes,
        );
    }

    pub fn handleInput(self: *Arena) !void {
        if (self.playerLifes > 0) {
            if (rl.isKeyDown(.right) or rl.isKeyDown(.d)) {
                self.player.rotate(2);
            }

            if (rl.isKeyDown(.left) or rl.isKeyDown(.a)) {
                self.player.rotate(-2);
            }

            if (rl.isKeyDown(.up) or rl.isKeyDown(.w)) {
                self.handleAccelerationInput(-0.5);
            }

            if (rl.isKeyDown(.down) or rl.isKeyDown(.s)) {
                self.handleAccelerationInput(0.5);
            }

            if (rl.isKeyDown(.space)) {
                try self.shoot();
            }
        }

        if (self.playerLifes == 0) {
            if (rl.isKeyDown(.enter)) {
                self.reset();
            }
        }
    }

    fn handleAccelerationInput(self: *Arena, speed: f32) void {
        self.player.accelerate(0, speed);

        if (!rl.isSoundPlaying(self.sounds.thrust)) {
            rl.playSound(self.sounds.thrust);
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
                continue;
            }

            if (self.checkProjectileCollision(&node.data) catch true) {
                self.projectiles.remove(node);
            }
        }
    }

    fn updateAsteroids(self: *Arena) void {
        const desiredCount = ASTEROIDS_MIN_COUNT + @divTrunc(self.playerScore, POINTS_PER_NEW_ASTEROID);

        if (self.asteroids.items.len < desiredCount) {
            for (self.asteroids.items.len..desiredCount) |_| {
                const a = self.generateRandomAsteroid();

                self.asteroids.add(a) catch unreachable;
            }
        }

        var iter = self.asteroids.iter();

        while (iter.next()) |node| {
            node.data.update();

            if (!node.data.isVisible(self.screen)) {
                node.data.deinit();
                self.asteroids.remove(node);

                continue;
            }

            if (self.player.collides(node.data.getBbox())) {
                self.handlePlayerCollision(node.data) catch unreachable;

                self.asteroids.remove(node);
            }
        }
    }

    fn updateNotifications(self: *Arena) void {
        const ts = std.time.milliTimestamp();

        var iter = self.notifications.iter();

        while (iter.next()) |n| {
            if (ts - n.data.createdAt > n.data.severity.lifetime()) {
                self.notifications.remove(n);
            }
        }
    }

    fn handlePlayerCollision(self: *Arena, a: asteroid.Asteroid) !void {
        self.decreasePlayerLifes();

        if (self.playerLifes == 0) {
            self.handlePlayerDeath();
            return;
        }

        self.handlePlayerStun();
        try self.destroyAsteroid(a);
    }

    fn handlePlayerDeath(self: *Arena) void {
        self.player.setState(.DEATH);
        self.notifications.clear();
    }

    fn handlePlayerStun(self: *Arena) void {
        self.player.setState(.STUN);
        self.player.position = utils.screenMiddle();
        self.player.velocity = rl.Vector2.zero();
        self.player.rotation = 0;
    }

    fn generateRandomAsteroid(self: *Arena) asteroid.Asteroid {
        const level = self.rand.enumValue(asteroid.Asteroid.Level);
        var position: rl.Vector2 = .{
            .x = @as(f32, @floatFromInt(self.rand.intRangeAtMost(i32, 0, rl.getScreenHeight()))),
            .y = @as(f32, @floatFromInt(self.rand.intRangeAtMost(i32, 0, rl.getScreenWidth()))),
        };

        if (self.rand.boolean()) {
            if (position.x > utils.screenWidth() / 2) {
                position.x = utils.screenWidth() + level.radius() - 1;
            } else {
                position.x = -level.radius() + 1;
            }
        } else {
            if (position.y > utils.screenHeight() / 2) {
                position.y = utils.screenHeight() + level.radius() - 1;
            } else {
                position.y = -level.radius() + 1;
            }
        }

        return asteroid.Asteroid.init(self.allocator, position, level, self.rand);
    }

    fn checkProjectileCollision(self: *Arena, p: *const projectile.Projectile) !bool {
        const bbox = p.getBbox();

        var iter = self.asteroids.iter();
        while (iter.next()) |node| {
            if (!node.data.isVisible(self.screen)) {
                continue;
            }

            if (node.data.collides(bbox)) {
                try self.handleProjectileHit(node.data);

                node.data.deinit();
                self.asteroids.remove(node);
                return true;
            }
        }

        return false;
    }

    fn handleProjectileHit(self: *Arena, a: asteroid.Asteroid) !void {
        self.increaseScore(a.level.destructionPoints());

        try self.destroyAsteroid(a);
    }

    fn destroyAsteroid(self: *Arena, a: asteroid.Asteroid) !void {
        self.playAsteroidBangSound(a.level);

        const separatesIn = a.level.separatesInto();

        for (0..separatesIn.count) |_| {
            const new = asteroid.Asteroid.init(self.allocator, a.position, separatesIn.level, self.rand);

            try self.asteroids.add(new);
        }
    }

    fn playAsteroidBangSound(self: *const Arena, level: asteroid.Asteroid.Level) void {
        const sound = switch (level) {
            .SMALL => self.sounds.bang_small,
            .MEDIUM => self.sounds.bang_medium,
            .LARGE => self.sounds.bang_large,
        };

        rl.playSound(sound);
    }

    fn increaseScore(self: *Arena, score: u32) void {
        const old = @divTrunc(self.playerScore, POINTS_PER_NEW_ASTEROID);

        self.playerScore += score;
        if (old != @divTrunc(self.playerScore, POINTS_PER_NEW_ASTEROID)) {
            self.notifications.add(.{
                .message = "More asteroids incoming!",
                .severity = .DEFAULT,
                .createdAt = std.time.milliTimestamp(),
            }) catch unreachable;
        }
    }

    fn decreasePlayerLifes(self: *Arena) void {
        if (self.playerLifes == 0) {
            return;
        }

        self.playerLifes -= 1;

        if (self.playerLifes == 1) {
            self.notifications.addFirst(.{
                .message = "SHIELDS ARE LOW",
                .severity = .HIGH,
                .createdAt = std.time.milliTimestamp(),
            }) catch unreachable;
        } else {
            self.notifications.add(.{
                .message = "We've been hit!",
                .createdAt = std.time.milliTimestamp(),
            }) catch unreachable;
        }
    }

    fn updatePlayer(self: *Arena) void {
        self.player.update();
    }
};
