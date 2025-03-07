const rl = @import("raylib");

const playerTexturePath = "resources/textures/player.png";

pub const Textures = struct {
    player: rl.Texture2D,

    pub fn load() !*const Textures {
        return &Textures{
            .player = try rl.loadTexture(playerTexturePath),
        };
    }
};
