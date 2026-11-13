const options = @import("build_options");
const std = @import("std");
const x11 = @import("x11");

const Context = @import("context.zig");
const Config = @import("config.zig");

pub fn main(init: std.process.Init) !void {
    const ctx: Context = .{
        .allocator = init.gpa,
        .io = init.io,
    };
    const stdout = std.Io.File.stdout();

    const args = try init.minimal.args.toSlice(init.arena.allocator());
    var once = false;
    var to_stdout = false;
    for (args[0..]) |arg| {
        if (std.mem.eql(u8, arg, "-v")) {
            try stdout.writeStreamingAll(ctx.io, options.name ++ "-" ++ options.version ++ "\n");
            return;
        } else if (std.mem.eql(u8, arg, "-s")) {
            to_stdout = true;
        } else if (std.mem.eql(u8, arg, "-1")) {
            once = true;
        }
    }

    var dpy: *x11.Display = undefined;
    if (!to_stdout) {
        dpy = x11.XOpenDisplay(null) orelse return error.CannotOpenDisplay;
    }
    defer {
        if (!to_stdout) _ = x11.XCloseDisplay(dpy);
    }

    var status: [Config.BUF_SIZE]u8 = undefined;
    var components: rttup: {
        var types: [Config.COMPONENTS.len]type = undefined;
        for (Config.COMPONENTS, 0..) |component, i| {
            types[i] = @TypeOf(component);
        }
        break :rttup @Tuple(&types);
    } = Config.COMPONENTS;
    defer {
        inline for (&components) |*component| {
            component.deinit(ctx);
        }
    }

    while (true) {
        var len: usize = 0;
        status[0] = 0;
        inline for (&components) |*component| {
            const text = try std.fmt.bufPrintSentinel(
                status[len..],
                @TypeOf(component.*).template,
                try component.args(ctx),
                0,
            );
            len += text.len;
        }

        if (to_stdout) {
            try stdout.writeStreamingAll(ctx.io, status[0..len]);
            try stdout.writeStreamingAll(ctx.io, "\n");
        } else {
            _ = x11.XStoreName(dpy, x11.DefaultRootWindow(dpy), &status);
            _ = x11.XFlush(dpy);
        }
        if (once) break;
        try std.Io.sleep(ctx.io, Config.PERIOD, .awake);
    }
}
