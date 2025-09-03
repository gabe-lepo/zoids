const std = @import("std");
const rl = @import("raylib");

const player_module = @import("player.zig");

// aliases
const Player = player_module.Player;

pub fn main() !void {
    rl.initWindow(1280, 720, "Zigray");
    defer rl.closeWindow();

    rl.setExitKey(rl.KeyboardKey.null); // No close key
    rl.setTargetFPS(60);

    var player1 = Player.init();

    while (!rl.windowShouldClose()) {
        player1.update();

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);
        player1.draw();
    }
}
