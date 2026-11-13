const package = @import("build.zig.zon");
const std = @import("std");
const Translator = @import("translate_c").Translator;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const options = b.addOptions();

    options.addOption([]const u8, "version", package.version);

    const t: Translator = .init(b.dependency("translate_c", .{}), .{
        .c_source_file = b.path("bindings.h"),
        .target = target,
        .optimize = optimize,
    });

    const x11_includes = b.graph.environ_map.get("X11_INCLUDE_PATHS") orelse
        @panic("X11_INCLUDE_PATHS missing");
    var x11_paths = std.mem.tokenizeScalar(u8, x11_includes, ':');

    while (x11_paths.next()) |p| {
        t.addSystemIncludePath(.{ .cwd_relative = p });
    }

    const exe = b.addExecutable(.{
        .name = "zstatus",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    options.addOption([]const u8, "name", exe.name);
    exe.root_module.addOptions("build_options", options);
    exe.root_module.linkSystemLibrary("X11", .{});
    if (b.option([]const u8, "runtime-library-paths", "RT lib paths")) |paths| {
        var it = std.mem.tokenizeScalar(u8, paths, ':');
        while (it.next()) |path| {
            exe.root_module.addRPath(.{ .cwd_relative = path });
        }
    }
    exe.root_module.addImport("x11", t.mod);

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    run_cmd.addPassthruArgs();

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_exe_tests.step);
}
