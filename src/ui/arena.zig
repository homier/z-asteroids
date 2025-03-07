const player = @import("../entities/player.zig");
const projectile = @import("../entities/projectile.zig");
const asteroid = @import("../entities/asteroid.zig");

const player_drawer = @import("player.zig");
const projectile_drawer = @import("projectile.zig");
const asteroid_drawer = @import("asteroid.zig");
const textures = @import("textures.zig");

pub const ArenaDrawer = struct {
    const Self = @This();

    debug: bool = false,

    player: player_drawer.PlayerDrawer,
    projectile: projectile_drawer.ProjectileDrawer,
    asteroid: asteroid_drawer.AsteroidDrawer,

    pub fn init(debug: bool) !Self {
        const t = try textures.Textures.load();

        return .{
            .debug = debug,
            .player = player_drawer.PlayerDrawer.init(debug, t.player),
            .projectile = projectile_drawer.ProjectileDrawer.init(debug),
            .asteroid = asteroid_drawer.AsteroidDrawer.init(debug),
        };
    }

    pub fn draw(
        self: *const Self,
        playerEntity: *const player.Player,
        projectiles: *const projectile.ProjectileRegistry,
        asteroids: *const asteroid.AsteroidRegistry,
    ) void {
        self.player.draw(playerEntity);
        self.projectile.draw(projectiles);
        self.asteroid.draw(asteroids);
    }
};
