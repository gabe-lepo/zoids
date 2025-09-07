const rl = @import("raylib");
const settings = @import("settings.zig");
const boids = @import("boids.zig");
const game = @import("game.zig");
const spatial = @import("spatial.zig");

pub const Renderer = struct {
    pub fn drawGame(game_state: *game.GameState) void {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(settings.WindowConfig.BACKGROUND_COLOR);

        drawBoids(game_state);
        drawUI(game_state);
        if (game_state.showGrid) drawGridCells(game_state);
    }

    fn drawBoids(game_state: *const game.GameState) void {
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
            settings.WindowConfig.GAME_INSTRUCTIONS,
            10,
            settings.WindowConfig.HEIGHT - 30,
            settings.WindowConfig.FONT_SIZE,
            rl.Color.gray,
        );
    }

    fn drawGridCells(game_state: *const game.GameState) void {
        const grid = &game_state.spatial_grid;
        const width = spatial.SpatialGrid.GRID_WIDTH;
        const height = spatial.SpatialGrid.GRID_HEIGHT;
        const cell_size = spatial.SpatialGrid.CELL_SIZE;

        for (0..height) |y| {
            for (0..width) |x| {
                const cell = &grid.cells[y][x];

                const cell_x = @as(f32, @floatFromInt(x)) * cell_size;
                const cell_y = @as(f32, @floatFromInt(y)) * cell_size;

                rl.drawRectangleLines(
                    @intFromFloat(cell_x),
                    @intFromFloat(cell_y),
                    @intFromFloat(cell_size),
                    @intFromFloat(cell_size),
                    rl.Color.dark_gray.alpha(0.3),
                );

                if (cell.count > 0) {
                    const count_text = rl.textFormat("%d", .{cell.count});
                    rl.drawText(
                        count_text,
                        @intFromFloat(cell_x + 2),
                        @intFromFloat(cell_y + 2),
                        12,
                        rl.Color.yellow,
                    );
                }
            }
        }
    }
};
