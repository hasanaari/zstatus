const std = @import("std");

const C = @import("components.zig");

pub const PERIOD: std.Io.Duration = .fromSeconds(1);
pub const BUF_SIZE: usize = 4096;

pub var COMPONENTS = .{
    C.Text("S "),
    C.RunCmd(&.{
        "sh",                                                                            "-c",
        "df -h --output=avail / | awk 'NR==2 {sub(/[KMGTPE]$/, \"&i\", $1); print $1}'",
    }),
    C.Text(" | M "),
    C.RunCmd(&.{ "sh", "-c", "free -h | awk '/^Mem:/ {print $3}'" }),
    C.Text(" | V "),
    C.RunCmd(&.{
        "sh",                                                                                                        "-c",
        "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '/MUTED/ { print \"x\"; next } { printf \"%d%%\", $2 * 100 }'",
    }),
    C.Text(" | B "),
    C.RunCmd(&.{ "cat", "/sys/class/power_supply/BAT0/capacity" }),
    C.Text("% | "),
    C.RunCmd(&.{ "date", "+%Y-%m-%d %H:%M:%S" }),
};
