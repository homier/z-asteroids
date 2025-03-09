const rl = @import("raylib");

const player = @import("../entities/player.zig");
const projectile = @import("../entities/projectile.zig");
const asteroid = @import("../entities/asteroid.zig");
const notification = @import("../entities/notification.zig");

const textures = @import("../resources/textures.zig");

const player_renderer = @import("player.zig");
const projectile_renderer = @import("projectile.zig");
const asteroid_renderer = @import("asteroid.zig");
const notification_renderer = @import("notification.zig");

const base = @import("base.zig");

const LIFE_BOX_GAP = 15;
const LIFE_BOX_WIDTH = 10;
const LIFE_BOX_HEIGHT = 30;
const LIFE_BOX_ANGLE = 15.0;
const LIFE_BOX_ROTATION_ORIGIN = rl.Vector2{ .x = LIFE_BOX_WIDTH / 2, .y = LIFE_BOX_HEIGHT / 2 };
const LIFE_BOX_COLOR_ACTIVE = rl.Color.white;
const LIFE_BOX_COLOR_INACTIVE = rl.Color.gray;

pub const ArenaRenderer = struct {
    const Self = @This();

    debug: bool = false,

    player: player_renderer.PlayerRenderer,
    projectile: projectile_renderer.ProjectileRenderer,
    asteroid: asteroid_renderer.AsteroidRenderer,
    notification: notification_renderer.NotificationRenderer,

    playerMaxLifes: u8,

    pub fn init(debug: bool, playerMaxLifes: u8, t: textures.Textures) !Self {
        return .{
            .debug = debug,
            .player = player_renderer.PlayerRenderer.init(debug, t.player),
            .projectile = projectile_renderer.ProjectileRenderer.init(debug),
            .asteroid = asteroid_renderer.AsteroidRenderer.init(debug),
            .notification = notification_renderer.NotificationRenderer.init(debug),

            .playerMaxLifes = playerMaxLifes,
        };
    }

    pub fn render(
        self: *const Self,
        playerEntity: *const player.Player,
        projectiles: *const projectile.ProjectileRegistry,
        asteroids: *const asteroid.AsteroidRegistry,
        notifications: *const notification.NotificationRegistry,
        playerScore: u32,
        playerLifes: u8,
    ) void {
        self.player.render(playerEntity);
        self.projectile.render(projectiles);
        self.asteroid.render(asteroids);
        self.notification.render(notifications);

        self.renderScore(playerScore);
        self.renderLifes(playerLifes);

        if (playerLifes == 0) {
            self.renderGameOver();
        }
    }

    fn renderScore(_: *const Self, score: u32) void {
        const text = rl.textFormat("%i", .{score});
        const size = rl.measureText(text, 30);

        rl.drawText(
            text,
            @divTrunc(rl.getScreenWidth(), 2) - @divTrunc(size, 2),
            base.TOP_BAR_POSITION.y,
            30,
            rl.Color.white,
        );
    }

    fn renderLifes(self: *const Self, lifes: u8) void {
        var lifeBox = rl.Rectangle{
            .x = 0,
            .y = base.TOP_BAR_POSITION.y,
            .width = LIFE_BOX_WIDTH,
            .height = LIFE_BOX_HEIGHT,
        };

        for (0..lifes) |_| {
            lifeBox.x += LIFE_BOX_GAP;

            rl.drawRectanglePro(lifeBox, LIFE_BOX_ROTATION_ORIGIN, LIFE_BOX_GAP, LIFE_BOX_COLOR_ACTIVE);
        }

        for (lifes..self.playerMaxLifes) |_| {
            lifeBox.x += 15;

            rl.drawRectanglePro(lifeBox, LIFE_BOX_ROTATION_ORIGIN, LIFE_BOX_ANGLE, LIFE_BOX_COLOR_INACTIVE);
        }
    }

    fn renderGameOver(_: *const Self) void {
        var size = rl.measureText("GAME OVER", 40);

        rl.drawText(
            "GAME OVER",
            @divTrunc(rl.getScreenWidth(), 2) - @divTrunc(size, 2),
            @divTrunc(rl.getScreenHeight(), 2),
            40,
            rl.Color.red,
        );

        size = rl.measureText("Press ENTER to restart", 30);
        rl.drawText(
            "Press ENTER to restart",
            @divTrunc(rl.getScreenWidth(), 2) - @divTrunc(size, 2),
            @divTrunc(rl.getScreenHeight(), 2) + 40,
            30,
            rl.Color.white,
        );
    }
};
