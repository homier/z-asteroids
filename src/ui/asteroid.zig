const rl = @import("raylib");

const asteroid = @import("../entities/asteroid.zig");
const renderer = @import("renderer.zig");

fn render(debug: bool, a: asteroid.Asteroid, _: usize) void {
    if (debug) {
        rl.drawCircleLinesV(a.position, a.radius, rl.Color.red);
    }

    for (a.edges.items) |edge| {
        rl.drawLineEx(edge.start, edge.end, 2.0, rl.Color.light_gray);
    }
}

pub const AsteroidRenderer = renderer.Renderer(asteroid.Asteroid, render);
