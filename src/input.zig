const rl = @import("raylib");
const boids = @import("boids.zig");
const utils = @import("utils.zig");
const game = @import("game.zig");
const settings = @import("settings.zig");

pub const InputHandler = struct {
    left_click_timer: f32 = 0,
    right_click_timer: f32 = 0,

    const CLICK_COOLDOWN = 0.15;
    const Self = @This();

    pub fn update(self: *Self, game_state: *game.GameState) void {
        const delta_time = rl.getFrameTime();

        if (self.left_click_timer > 0) self.left_click_timer -= delta_time;
        if (self.right_click_timer > 0) self.right_click_timer -= delta_time;

        self.handleKeyboard(game_state);
        self.handleMouse(game_state);
    }

    fn handleKeyboard(self: *Self, game_state: *game.GameState) void {
        _ = self;
        // Reset game
        if (rl.isKeyPressed(rl.KeyboardKey.r)) {
            game_state.reset();
        }

        // Pause game
        if (rl.isKeyPressed(rl.KeyboardKey.p)) {
            game_state.paused = !game_state.paused;
        }
    }

    fn handleMouse(self: *Self, game_state: *game.GameState) void {
        // Add boids
        if (rl.isMouseButtonDown(rl.MouseButton.left) and self.left_click_timer <= 0) {
            var rng = utils.PrngHelper.getRng();
            const new_boids = rng.intRangeAtMost(usize, settings.BoidConfig.BOIDS_PER_CLICK_MIN, settings.BoidConfig.BOIDS_PER_CLICK_MAX);
            game_state.addBoids(new_boids);
            self.left_click_timer = CLICK_COOLDOWN;
        }

        // Debug draw controller
        if (rl.isMouseButtonPressed(rl.MouseButton.right) and self.right_click_timer <= 0) {
            game_state.current_debug_opt = switch (game_state.current_debug_opt) {
                .none => .separation_radius,
                .separation_radius => .alignment_radius,
                .alignment_radius => .velocity_vector,
                .velocity_vector => .all,
                .all => .none,
            };
            self.right_click_timer = CLICK_COOLDOWN;
        }
    }
};
