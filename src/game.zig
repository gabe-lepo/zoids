const std = @import("std");
const rl = @import("raylib");
const boids = @import("boids.zig");
const settings = @import("settings.zig");

pub const GameState = struct {
    boids_arr: [settings.BoidConfig.MAX_BOIDS]boids.Boid,
    active_boid_count: usize,
    current_debug_opt: boids.DebugOptions,
    paused: bool,

    const Self = @This();

    pub fn init() Self {
        var state = Self{
            .boids_arr = undefined,
            .active_boid_count = settings.BoidConfig.INITIAL_BOIDS,
            .current_debug_opt = boids.DebugOptions.none,
            .paused = false,
        };
        state.initBoids();
        return state;
    }

    pub fn initBoids(self: *Self) void {
        for (self.boids_arr[0..self.active_boid_count]) |*boid| {
            boid.* = boids.Boid.initRandom();
        }
    }

    pub fn addBoids(self: *Self, count: usize) void {
        const old_count = self.active_boid_count;
        self.active_boid_count = @min(old_count + count, self.boids_arr.len);

        for (self.boids_arr[old_count..self.active_boid_count]) |*boid| {
            boid.* = boids.Boid.initRandom();
        }
    }

    pub fn reset(self: *Self) void {
        self.active_boid_count = settings.BoidConfig.INITIAL_BOIDS;
        self.initBoids();
    }

    pub fn update(self: *Self) void {
        if (self.paused) return;

        for (self.boids_arr[0..self.active_boid_count]) |*boid| {
            boid.flock(self.boids_arr[0..self.active_boid_count]);
            boid.update();
        }
    }
};
