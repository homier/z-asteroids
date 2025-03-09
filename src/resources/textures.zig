const rl = @import("raylib");

pub const Textures = struct {
    player: rl.Texture2D,

    pub fn load() !Textures {
        return .{
            .player = try loadTexture(@embedFile("textures_player"), "player.png"),
        };
    }

    fn loadTexture(comptime data: anytype, _: [:0]const u8) !rl.Texture2D {
        const image = try rl.loadImageFromMemory(".png", data);
        defer rl.unloadImage(image);

        return rl.loadTextureFromImage(image);
    }

    pub fn deinit(self: *const Textures) void {
        rl.unloadTexture(self.player);
    }
};
