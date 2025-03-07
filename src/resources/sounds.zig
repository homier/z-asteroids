const rl = @import("raylib");

pub const Sounds = struct {
    fire: rl.Sound,
    bang_small: rl.Sound,
    bang_medium: rl.Sound,
    bang_large: rl.Sound,

    pub fn load() !Sounds {
        return .{
            .fire = try rl.loadSound("resources/audio/fire.wav"),
            .bang_small = try rl.loadSound("resources/audio/bang_small.wav"),
            .bang_medium = try rl.loadSound("resources/audio/bang_medium.wav"),
            .bang_large = try rl.loadSound("resources/audio/bang_large.wav"),
        };
    }

    pub fn deinit(self: *const Sounds) void {
        rl.unloadSound(self.fire);
        rl.unloadSound(self.bang_small);
        rl.unloadSound(self.bang_medium);
        rl.unloadSound(self.bang_large);
    }
};
