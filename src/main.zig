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

    var game_state = game.GameState.init();
    var input_handler = input.InputHandler{};

    while (!rl.windowShouldClose()) {
        input_handler.update(&game_state);
        game_state.update();
        renderer.Renderer.drawGame(&game_state);
    }
}
