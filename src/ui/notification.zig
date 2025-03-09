const std = @import("std");
const rl = @import("raylib");

const notification_entity = @import("../entities/notification.zig");
const renderer = @import("renderer.zig");
const base = @import("base.zig");

const NOTIFICATION_COLOR_DEFAULT = rl.Color.white;
const NOTIFICATION_COLOR_HIGH = rl.Color.orange;
const NOTIFICATION_HEIGHT = 20;
const NOTIFICATION_BOX_PADDING = 40;

fn render(_: bool, notification: notification_entity.Notification, index: usize) void {
    const color = switch (notification.severity) {
        .DEFAULT => NOTIFICATION_COLOR_DEFAULT,
        .HIGH => NOTIFICATION_COLOR_HIGH,
    };
    const size = rl.measureText(notification.message, NOTIFICATION_HEIGHT);
    const indexF = @as(i32, @intCast(index));

    rl.drawText(
        notification.message,
        rl.getScreenWidth() - size - NOTIFICATION_BOX_PADDING,
        base.TOP_BAR_POSITION_Y * (indexF + 1),
        NOTIFICATION_HEIGHT,
        color,
    );
}

pub const NotificationRenderer = renderer.Renderer(notification_entity.Notification, render);
