const rl = @import("raylib");

const projectile = @import("../entities/projectile.zig");
const renderer = @import("renderer.zig");

fn render(_: bool, p: projectile.Projectile, _: usize) void {
    rl.drawCircleV(p.position, p.radius, rl.Color.red);
}

pub const ProjectileRenderer = renderer.Renderer(projectile.Projectile, render);
