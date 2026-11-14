const std = @import("std");

const C = @import("component.zig").Component;
const A = @import("args.zig");

pub const PERIOD: std.Io.Duration = .fromSeconds(1);
pub const BUF_SIZE: usize = 4096;

pub const COMPONENTS = .{
    C("S {s}", A.RunCmd(&.{
        "sh",                                                                            "-c",
        "df -h --output=avail / | awk 'NR==2 {sub(/[KMGTPE]$/, \"&i\", $1); print $1}'",
    })),
    C(" | M {s}", A.RunCmd(&.{ "sh", "-c", "free -h | awk '/^Mem:/ {print $3}'" })),
    C(" | V {s}", A.RunCmd(&.{
        "sh",                                                                                                        "-c",
        "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '/MUTED/ { print \"x\"; next } { printf \"%d%%\", $2 * 100 }'",
    })),
    C(" | B {s}%", A.RunCmd(&.{ "cat", "/sys/class/power_supply/BAT0/capacity" })),
    C(" | {s}", A.RunCmd(&.{ "date", "+%Y-%m-%d %H:%M:%S" })),
};
