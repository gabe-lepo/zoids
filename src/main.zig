const std = @import("std");
const rl = @import("raylib");

const player = @import("player.zig");
const settings = @import("settings.zig");
const boids = @import("boids.zig");

// aliases
const Boid = boids.Boid;

pub fn main() !void {
    rl.initWindow(settings.WINDOW_WIDTH, settings.WINDOW_HEIGHT, "Zigray");
    defer rl.closeWindow();

    rl.setExitKey(rl.KeyboardKey.null); // No close key
    rl.setTargetFPS(settings.FPS);

    const MAX_BOIDS = 1000;
    var boids_arr: [MAX_BOIDS]Boid = undefined;
    var active_boid_count: usize = 50;

    const initBoids = struct {
        fn init(boidz: []Boid, count: usize) void {
            for (boidz[0..count]) |*boid| {
                boid.* = Boid.initRandom();
            }
        }
    }.init;

    initBoids(boids_arr[0..], active_boid_count);

    var current_debug_opt = boids.DebugOptions.none;

    while (!rl.windowShouldClose()) {
        // Reset to starting count
        if (rl.isKeyPressed(rl.KeyboardKey.r)) {
            active_boid_count = 50;
            initBoids(boids_arr[0..], active_boid_count);
        }

        // Add some more on left click( after debouncing)
        if (rl.isMouseButtonDown(rl.MouseButton.left)) {
            var rng = boids.getRng();
            const new_boids = rng.intRangeAtMost(usize, 5, 10);
            const old_count = active_boid_count;

            // Limit to max
            active_boid_count = @min(active_boid_count + new_boids, MAX_BOIDS);

            //init new ones
            for (boids_arr[old_count..active_boid_count]) |*boid| {
                boid.* = Boid.initRandom();
            }
        }

        // Debug visuals with right click (with debouncing)
        if (rl.isMouseButtonPressed(rl.MouseButton.right)) {
            current_debug_opt = switch (current_debug_opt) {
                .none => .separation_radius,
                .separation_radius => .alignment_radius,
                .alignment_radius => .velocity_vector,
                .velocity_vector => .all,
                .all => .none,
            };
        }

        // update active boids
        for (boids_arr[0..active_boid_count]) |*boid| {
            boid.flock(boids_arr[0..active_boid_count]);
            boid.update();
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(settings.BACKGROUND_COLOR);

        // draw active boids
        for (boids_arr[0..active_boid_count]) |boid| {
            if (current_debug_opt == .none) {
                boid.draw();
            } else {
                boid.drawDebug(current_debug_opt);
            }
        }

        // Display boid count
        const count_text = rl.textFormat("Boids: %d", .{active_boid_count});
        rl.drawText(count_text, 10, 10, 20, rl.Color.white);
    }
}
