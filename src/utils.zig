const rl = @import("raylib");

pub fn screenWidth() f32 {
    return @as(f32, @floatFromInt(rl.getScreenWidth()));
}

pub fn screenHeight() f32 {
    return @as(f32, @floatFromInt(rl.getScreenHeight()));
}

pub fn screenRectangle() rl.Rectangle {
    return rl.Rectangle.init(0, 0, screenWidth(), screenHeight());
}

pub fn verticalAccelerationVector(speed: f32) rl.Vector2 {
    return rl.Vector2{ .x = 0, .y = speed };
}

pub fn horizontalAccelerationVector(speed: f32) rl.Vector2 {
    return rl.Vector2{ .x = speed, .y = 0 };
}
