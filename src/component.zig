pub fn Component(
    comptime fmt_: []const u8,
    comptime args_: anytype,
) struct {
    pub const fmt = fmt_;
    args: @TypeOf(args_) = args_,
} {
    return .{};
}
