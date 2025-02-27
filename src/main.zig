const std = @import("std");
const rl = @import("raylib");

const Arena = @import("./arena.zig").Arena;

const screenWidth = 1280;
const screenHeight = 720;
const targetFps = 60;

pub fn main() !void {
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

    const backgroundSound = try rl.loadSound("resources/audio/background.mp3");
    defer rl.unloadSound(backgroundSound);

    var arena = Arena.init(&rand, backgroundSound);
    try arena.loop();
}
