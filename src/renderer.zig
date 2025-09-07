const rl = @import("raylib");
const settings = @import("settings.zig");
const boids = @import("boids.zig");
const game = @import("game.zig");

pub const Renderer = struct {
    pub fn drawGame(game_state: *game.GameState) void {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(settings.WindowConfig.BACKGROUND_COLOR);

        drawBoids(game_state);
        drawUI(game_state);
    }

    fn drawBoids(game_state: *game.GameState) void {
        for (game_state.boids_arr[0..game_state.active_boid_count]) |boid| {
            if (game_state.current_debug_opt == .none) {
                boid.draw();
            } else {
                boid.drawDebug(game_state.current_debug_opt);
            }
        }
    }

    fn drawUI(game_state: *const game.GameState) void {
        rl.drawFPS(10, 10);

        const count_text = rl.textFormat(
            "%d Boids",
            .{
                game_state.active_boid_count,
            },
        );
        rl.drawText(count_text, 10, 30, 20, rl.Color.white);

        if (game_state.paused) {
            const pause_text = "PAUSED";
            const font_size = settings.WindowConfig.FONT_SIZE;
            const text_width = rl.measureText(pause_text, font_size);

            const x = settings.WindowConfig.WIDTH / 2.0 - @as(f32, @floatFromInt(text_width)) / 2.0;
            const y = settings.WindowConfig.HEIGHT / 2.0 - @as(f32, @floatFromInt(font_size)) / 2.0;

            rl.drawText(
                pause_text,
                @as(i32, @intFromFloat(x)),
                @as(i32, @intFromFloat(y)),
                settings.WindowConfig.FONT_SIZE,
                rl.Color.yellow,
            );
        }

        rl.drawText(
            "Left Click: Add Boids | Right Click: Debug | R: Reset | P: Pause",
            10,
            settings.WindowConfig.HEIGHT - 30,
            16,
            rl.Color.gray,
        );
    }
};
