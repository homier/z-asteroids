const rl = @import("raylib");

const asteroid = @import("../entities/asteroid.zig");
const drawer = @import("drawer.zig");

fn draw(debug: bool, a: asteroid.Asteroid) void {
    if (debug) {
        rl.drawCircleLinesV(a.position, a.radius, rl.Color.red);
    }

    for (a.edges) |edge| {
        rl.drawLineEx(edge.start, edge.end, 3.0, rl.Color.dark_gray);
    }
}

pub const AsteroidDrawer = drawer.Drawer(asteroid.Asteroid, draw);
