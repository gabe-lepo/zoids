const std = @import("std");
const rl = @import("raylib");

const player = @import("player.zig");
const settings = @import("settings.zig");

// aliases
const Player = player.Player;

pub fn main() !void {
    rl.initWindow(settings.WINDOW_WIDTH, settings.WINDOW_HEIGHT, "Zigray");
    defer rl.closeWindow();

    rl.setExitKey(rl.KeyboardKey.null); // No close key
    rl.setTargetFPS(settings.FPS);

    var player1 = Player.init();

    while (!rl.windowShouldClose()) {
        player1.update();

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(settings.BACKGROUND_COLOR);
        player1.draw();
    }
}
