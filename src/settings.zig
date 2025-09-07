const rl = @import("raylib");

pub const WindowConfig = struct {
    pub const TITLE = "Zigray";
    // use f32s not comptime_f, less typecasting
    pub const WIDTH: f32 = 2560.0;
    pub const HEIGHT: f32 = 1440.0 - 75.0;
    pub const BACKGROUND_COLOR = rl.Color.black;
    pub const FPS = 60;
    pub const FONT_SIZE = 20;
    pub const GAME_INSTRUCTIONS: [:0]const u8 = "Left Click: Add Boids | Right Click: Debug | R: Reset | P: Pause | G: Show grid";
};

pub const BoidConfig = struct {
    // Flock sizing
    pub const MAX_BOIDS = 5000;
    pub const INITIAL_BOIDS = 500;
    pub const BOIDS_PER_CLICK_MIN = 100;
    pub const BOIDS_PER_CLICK_MAX = 250;

    // Flock behaviors
    pub const SIZE = 8.0;
    pub const MAX_SPEED = 4.0;
    pub const MAX_FORCE = 0.05;
    pub const SEPARATION_RADIUS = 16.0;
    pub const SEPARATION_WEIGHT = 1.5;
    pub const ALIGNMENT_RADIUS = 64.0;
    pub const ALIGNMENT_WEIGHT = 1.2;
    pub const COHESION_RADIUS = 64.0;
    pub const COHESION_WEIGHT = 1.0;
};
