const rl = @import("raylib");

const projectile = @import("../entities/projectile.zig");
const drawer = @import("drawer.zig");

fn draw(_: bool, p: projectile.Projectile) void {
    rl.drawCircleV(p.position, p.radius, rl.Color.red);
}

pub const ProjectileDrawer = drawer.Drawer(projectile.Projectile, draw);
