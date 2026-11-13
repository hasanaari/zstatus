const std = @import("std");

const Context = @import("context.zig");

pub fn RunCmd(comptime argv: []const []const u8) struct {
    output: ?[]u8 = null,

    pub const template = "{s}";

    pub fn args(self: *@This(), ctx: Context) !struct { []const u8 } {
        const result = try std.process.run(ctx.allocator, ctx.io, .{
            .argv = argv,
        });
        defer ctx.allocator.free(result.stderr);
        errdefer ctx.allocator.free(result.stdout);

        if (!result.term.success()) return error.CommandFailed;

        if (self.output) |old| ctx.allocator.free(old);
        self.output = result.stdout;

        return .{std.mem.trimEnd(u8, result.stdout, "\n")};
    }

    pub fn deinit(self: *@This(), ctx: Context) void {
        if (self.output) |output| ctx.allocator.free(output);
        self.output = null;
    }
} {
    return .{};
}

pub fn Text(comptime text: []const u8) struct {
    pub const template = "{s}";

    pub fn args(_: *@This(), _: Context) !struct { []const u8 } {
        return .{text};
    }

    pub fn deinit(_: *@This(), _: Context) void {}
} {
    return .{};
}
