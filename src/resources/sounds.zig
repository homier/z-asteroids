const rl = @import("raylib");

pub const Sounds = struct {
    fire: rl.Sound,
    bang_small: rl.Sound,
    bang_medium: rl.Sound,
    bang_large: rl.Sound,
    thrust: rl.Sound,

    pub fn load() !Sounds {
        return .{
            .fire = try loadSound(@embedFile("sounds_fire"), "fire.wav"),
            .bang_small = try loadSound(@embedFile("sounds_bang_small"), "bang_small.wav"),
            .bang_medium = try loadSound(@embedFile("sounds_bang_medium"), "bang_medium.wav"),
            .bang_large = try loadSound(@embedFile("sounds_bang_large"), "bang_large.wav"),
            .thrust = try loadSound(@embedFile("sounds_thrust"), "thrust.wav"),
        };
    }

    fn loadSound(comptime data: anytype, _: [:0]const u8) !rl.Sound {
        const wave = try rl.loadWaveFromMemory(".wav", data);
        defer rl.unloadWave(wave);

        return rl.loadSoundFromWave(wave);
    }

    pub fn deinit(self: *const Sounds) void {
        rl.unloadSound(self.fire);
        rl.unloadSound(self.bang_small);
        rl.unloadSound(self.bang_medium);
        rl.unloadSound(self.bang_large);
        rl.unloadSound(self.thrust);
    }
};
