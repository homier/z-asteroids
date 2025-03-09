const std = @import("std");

const STUN_LIFETIME = 3_000; // 3 seconds
const ALIVE_LIFETIME = 0;
const DEATH_LIFETIME = std.math.maxInt(i64);

pub const PlayerState = struct {
    pub const State = enum {
        const Self = @This();

        STUN,
        ALIVE,
        DEATH,

        pub fn lifetime(self: Self) i64 {
            return switch (self) {
                .STUN => STUN_LIFETIME,
                .ALIVE => ALIVE_LIFETIME,
                .DEATH => DEATH_LIFETIME,
            };
        }

        pub fn previous(self: Self) Self {
            return switch (self) {
                .STUN => .ALIVE,
                else => self,
            };
        }

        pub fn finite(self: Self) bool {
            return self == .DEATH;
        }
    };

    s: State = .STUN,
    changedAt: i64 = 0,

    pub fn init() PlayerState {
        return .{ .changedAt = std.time.milliTimestamp() };
    }

    pub fn reset(self: *PlayerState) void {
        self.s = .STUN;
        self.changedAt = std.time.milliTimestamp();
    }

    pub fn update(self: *PlayerState) void {
        if (self.s.finite()) {
            return;
        }

        if (self.s.previous() == self.s) {
            return;
        }

        const now = std.time.milliTimestamp();
        if (now - self.changedAt >= self.s.lifetime()) {
            self.s = self.s.previous();
            self.changedAt = now;
        }
    }

    pub fn set(self: *PlayerState, state: State) void {
        if (self.s.finite()) {
            return;
        }

        const now = std.time.milliTimestamp();
        if (now - self.changedAt < self.s.lifetime()) {
            return;
        }

        self.s = state;
        self.changedAt = now;
    }

    pub fn canCollide(self: *const PlayerState) bool {
        return switch (self.s) {
            .ALIVE => true,
            else => false,
        };
    }
};
