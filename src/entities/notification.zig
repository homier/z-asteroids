const std = @import("std");

const entity_registry = @import("entity_registry.zig");

pub const NOTIFICATION_LIFETIME_DEFAULT = 2_000; // 2 seconds
pub const NOTIFICATION_LIFETIME_HIGH = std.math.maxInt(i64);

pub const NotificationRegistry = entity_registry.EntityRegistry(Notification);

pub const Notification = struct {
    const Severity = enum {
        DEFAULT,
        HIGH,

        pub fn lifetime(self: @This()) i64 {
            return switch (self) {
                .DEFAULT => NOTIFICATION_LIFETIME_DEFAULT,
                .HIGH => NOTIFICATION_LIFETIME_HIGH,
            };
        }
    };

    severity: Severity = .DEFAULT,

    message: [:0]const u8,
    createdAt: i64,
};
