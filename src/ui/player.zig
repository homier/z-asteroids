const std = @import("std");
const rl = @import("raylib");

const player = @import("../entities/player.zig");

pub const PlayerRenderer = struct {
    const Self = @This();

    debug: bool = false,
    texture: rl.Texture2D,
    textureSize: rl.Rectangle = rl.Rectangle.init(0, 0, 128, 128),

    pub fn init(debug: bool, texture: rl.Texture2D) Self {
        return .{ .debug = debug, .texture = texture };
    }

    pub fn render(self: *const Self, entity: *const player.Player) void {
        if (self.debug) {
            rl.drawLineV(
                rl.Vector2.init(entity.bbox.x, entity.bbox.y + entity.height / 2),
                rl.Vector2.init(entity.bbox.x + entity.width, entity.bbox.y + entity.height / 2),
                rl.Color.green,
            );
            rl.drawLineV(
                rl.Vector2.init(entity.bbox.x + entity.width / 2, entity.bbox.y),
                rl.Vector2.init(entity.bbox.x + entity.width / 2, entity.bbox.y + entity.height),
                rl.Color.green,
            );
            rl.drawRectangleLinesEx(entity.bbox, 2.0, rl.Color.red);
        }

        self.texture.drawPro(
            self.textureSize,
            .{
                .x = entity.position.x,
                .y = entity.position.y,
                .width = entity.width,
                .height = entity.height,
            },
            .{
                .x = entity.width / 2,
                .y = entity.height / 2,
            },
            entity.rotation,
            rl.Color.white,
        );

        if (entity.state.s == .STUN) {
            const textPosition = entity.position.add(.{ .x = entity.width, .y = entity.height + 10 });

            const font = rl.getFontDefault() catch null;
            if (font != null) {
                const remainingTs = entity.state.s.lifetime() - (std.time.milliTimestamp() - entity.state.changedAt);
                const remainingSeconds = @divTrunc(remainingTs, 1000);
                const remainingMillis = @mod(remainingTs, 1000);

                const text = rl.textFormat("SHIELD'S ON: %i.%ds", .{ remainingSeconds, remainingMillis });

                rl.drawCircleLinesV(entity.position, entity.height / 2, rl.Color.dark_gray);
                rl.drawTextEx(font.?, text, textPosition, 16, 1.0, rl.Color.dark_gray);
            }
        }
    }
};
