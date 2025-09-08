const std = @import("std");
const rl = @import("raylib");
const boids = @import("boids.zig");
const settings = @import("settings.zig");
const spatial = @import("spatial.zig");

pub const GameState = struct {
    boids_arr: [settings.BoidConfig.MAX_BOIDS]boids.Boid,
    active_boid_count: usize,
    current_debug_opt: boids.DebugOptions,
    paused: bool,

    // Spatial partitioning perf
    spatial_grid: spatial.SpatialGrid,
    showGrid: bool,

    // Fixed buffer instead of array list
    // PERF: Need more in nearby boids buf
    nearby_boids_buf: [256]usize,
    nearby_boids_count: usize,

    const Self = @This();

    pub fn init() !Self {
        var state = Self{
            .boids_arr = undefined,
            .active_boid_count = settings.BoidConfig.INITIAL_BOIDS,
            .current_debug_opt = boids.DebugOptions.none,
            .paused = false,

            .spatial_grid = spatial.SpatialGrid.init(),
            .showGrid = false,
            .nearby_boids_buf = undefined,
            .nearby_boids_count = 0,
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

        // Clear and rebuild spatial grid
        self.spatial_grid.clear();
        for (0..self.active_boid_count) |i| {
            self.spatial_grid.addBoid(i, self.boids_arr[i].position);
        }

        // Update each boid using only nearby boids
        // PERF: looping through all boids calling functions that... loop through all boids
        for (0..self.active_boid_count) |i| {
            self.spatial_grid.getNearbyBoids(
                self.boids_arr[i].position,
                &self.nearby_boids_buf,
                &self.nearby_boids_count,
            );

            self.boids_arr[i].flock(
                self.boids_arr[0..self.active_boid_count],
                self.nearby_boids_buf[0..self.nearby_boids_count],
            );
            self.boids_arr[i].update();
        }
    }

    pub fn getNearbyBoidsCount(self: *const Self) usize {
        return self.nearby_boids_count;
    }
};
