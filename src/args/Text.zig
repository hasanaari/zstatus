const Context = @import("../context.zig");

pub fn Text(comptime text: []const u8) struct {
    pub fn get(_: *@This(), _: Context) !struct { []const u8 } {
        return .{text};
    }

    pub fn deinit(_: *@This(), _: Context) void {}
} {
    return .{};
}
