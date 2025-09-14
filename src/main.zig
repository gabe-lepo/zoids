const std = @import("std");
const rl = @import("raylib");
const settings = @import("settings.zig");
const game = @import("game.zig");
const input = @import("input.zig");
const renderer = @import("renderer.zig");

pub fn main() !void {
    rl.initWindow(
        @as(i32, @intFromFloat(settings.WindowConfig.WIDTH)),
        @as(i32, @intFromFloat(settings.WindowConfig.HEIGHT)),
        settings.WindowConfig.TITLE,
    );
    defer rl.closeWindow();

    rl.setExitKey(rl.KeyboardKey.null);
    rl.setTargetFPS(settings.WindowConfig.FPS);

    // Cant stack alloc game state with more than 13k max boids
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var game_state = try allocator.create(game.GameState);
    defer allocator.destroy(game_state);
    game_state.* = try game.GameState.init();

    var input_handler = input.InputHandler{};

    while (!rl.windowShouldClose()) {
        input_handler.update(game_state);
        game_state.updateStaggered();
        renderer.Renderer.drawGame(game_state);
    }
}
