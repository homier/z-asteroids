const std = @import("std");
const rl = @import("raylib");

const Arena = @import("./arena.zig").Arena;
const utils = @import("utils.zig");
const sounds = @import("resources/sounds.zig");
const textures = @import("resources/textures.zig");

const screenWidth = 1280;
const screenHeight = 720;
const targetFps = 60;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    rl.initWindow(screenWidth, screenHeight, "Asteroids");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(targetFps);

    rl.initAudioDevice(); // Initialize audio device
    defer rl.closeAudioDevice(); // Close audio device

    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();

    const soundResources = try sounds.Sounds.load();
    defer soundResources.deinit();

    const textureResources = try textures.Textures.load();
    defer textureResources.deinit();

    var arena = try Arena.init(allocator, &rand, soundResources, textureResources);
    defer arena.deinit();

    while (!rl.windowShouldClose()) {
        try arena.handleInput();
        arena.update();
        arena.render();
    }
}
