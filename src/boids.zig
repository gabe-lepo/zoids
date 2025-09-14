const std = @import("std");
const rl = @import("raylib");
const settings = @import("settings.zig");
const utils = @import("utils.zig");
const game = @import("game.zig");

fn vector2Limit(vec: rl.Vector2, maxMagnitude: f32) rl.Vector2 {
    const mag = vec.length();
    return if (mag > maxMagnitude) vec.normalize().scale(maxMagnitude) else vec;
}

fn vector2Random() rl.Vector2 {
    var rng = utils.PrngHelper.getRng();

    return rl.Vector2{
        // Vec of rand [-2..2]
        .x = rng.float(f32) * 4.0 - 2.0,
        .y = rng.float(f32) * 4.0 - 2.0,
    };
}

fn distanceSquared(a: rl.Vector2, b: rl.Vector2) f32 {
    const distance_x = a.x - b.x;
    const distance_y = a.y - b.y;
    return distance_x * distance_x + distance_y * distance_y;
}

pub const DebugOptions = enum {
    none,
    separation_radius,
    alignment_radius,
    velocity_vector,
    all,
};

const bconfig = settings.BoidConfig;

pub const Boid = struct {
    // Core
    position: rl.Vector2,
    velocity: rl.Vector2,
    acceleration: rl.Vector2,
    maxSpeed: f32 = bconfig.MAX_SPEED,
    maxForce: f32 = bconfig.MAX_FORCE,

    // Behavior radii
    separationRadius: f32 = bconfig.SEPARATION_RADIUS,
    alignmentRadius: f32 = bconfig.ALIGNMENT_RADIUS,
    cohesionRadius: f32 = bconfig.COHESION_RADIUS,

    // Behavior weighting
    separationWeight: f32 = bconfig.SEPARATION_WEIGHT,
    alignmentWeight: f32 = bconfig.ALIGNMENT_WEIGHT,
    cohesionWeight: f32 = bconfig.COHESION_WEIGHT,

    // Visual props
    size: f32 = bconfig.SIZE,
    color: rl.Color = rl.Color.white,

    const Self = @This();

    pub fn initSpecific(position: rl.Vector2) Self {
        return Self{
            .position = position,
            .velocity = vector2Random(),
            .acceleration = rl.Vector2.zero(),
        };
    }

    pub fn initRandom() Self {
        var rng = utils.PrngHelper.getRng();

        return Self.initSpecific(rl.Vector2{
            .x = rng.float(f32) * settings.WindowConfig.WIDTH,
            .y = rng.float(f32) * settings.WindowConfig.HEIGHT,
        });
    }

    // ----------------
    // Boid algo funcs:
    // * Flocking
    // * Separation
    // * Alignment
    // * Cohesion
    // * Seeking
    // ----------------

    pub fn updateFlockOptimize1(self: *Self, all_boids: []const Boid, nearby_indices: []const usize) void {
        const sep_radius_sq = self.separationRadius * self.separationRadius;
        const align_radius_sq = self.alignmentRadius * self.alignmentRadius;

        const self_pos = self.position;
        const self_vel = self.velocity;

        var sep_force = rl.Vector2.zero();
        var align_vel_sum = rl.Vector2.zero();
        var cohes_pos_sum = rl.Vector2.zero();

        var sep_count: f32 = 0.0;
        var other_count: f32 = 0.0; // For both alignment and cohesion

        // Single pass with early termination optimizations
        for (nearby_indices) |boid_idx| {
            const other = all_boids[boid_idx];
            const dx = self_pos.x - other.position.x;
            const dy = self_pos.y - other.position.y;
            const dist_sq = dx * dx + dy * dy;

            if (dist_sq == 0.0) continue;

            // Separation (closest neighbors)
            if (dist_sq < sep_radius_sq) {
                // Use 1/dist instead of 1/dist^2 for less aggressive separation
                const inv_dist = 1.0 / @sqrt(dist_sq);
                sep_force.x += dx * inv_dist;
                sep_force.y += dy * inv_dist;
                sep_count += 1.0;
            }

            // Alignment and cohesion (same radius)
            if (dist_sq < align_radius_sq) {
                align_vel_sum = align_vel_sum.add(other.velocity);
                cohes_pos_sum = cohes_pos_sum.add(other.position);
                other_count += 1.0;
            }
        }

        var total_force = rl.Vector2.zero();

        // Apply separation
        if (sep_count > 0.0) {
            sep_force = sep_force.scale(1.0 / sep_count);
            if (sep_force.lengthSqr() > 0.001) {
                sep_force = sep_force.normalize().scale(self.maxSpeed).subtract(self_vel);
                sep_force = vector2Limit(sep_force, self.maxForce);
                total_force = total_force.add(sep_force.scale(self.separationWeight));
            }
        }

        // Apply alignment and cohesion together
        if (other_count > 0.0) {
            // Alignment
            var align_force = align_vel_sum.scale(1.0 / other_count);
            if (align_force.lengthSqr() > 0.001) {
                align_force = align_force.normalize().scale(self.maxSpeed).subtract(self_vel);
                align_force = vector2Limit(align_force, self.maxForce);
                total_force = total_force.add(align_force.scale(self.alignmentWeight));
            }

            // Cohesion (inline seek)
            const center = cohes_pos_sum.scale(1.0 / other_count);
            var cohes_force = center.subtract(self_pos);
            if (cohes_force.lengthSqr() > 0.001) {
                cohes_force = cohes_force.normalize().scale(self.maxSpeed).subtract(self_vel);
                cohes_force = vector2Limit(cohes_force, self.maxForce);
                total_force = total_force.add(cohes_force.scale(self.cohesionWeight));
            }
        }

        self.acceleration = self.acceleration.add(total_force);
    }

    // pub fn updateFlock(self: *Self, all_boids: []const Boid, nearby_indices: []const usize) void {
    //     const sep = self.separate(all_boids, nearby_indices);
    //     const ali = self.alignment(all_boids, nearby_indices);
    //     const coh = self.cohesion(all_boids, nearby_indices);
    //
    //     self.acceleration = self.acceleration
    //         .add(sep.scale(self.separationWeight))
    //         .add(ali.scale(self.alignmentWeight))
    //         .add(coh.scale(self.cohesionWeight));
    // }

    // fn separate(self: *const Self, all_boids: []const Boid, nearby_indices: []const usize) rl.Vector2 {
    //     var steer = rl.Vector2.zero();
    //     var count: f32 = 0.0;
    //     const separation_radius_sq = self.separationRadius * self.separationRadius;
    //
    //     for (nearby_indices) |boid_idx| {
    //         const other = &all_boids[boid_idx];
    //         const dist_sq = distanceSquared(self.position, other.position);
    //
    //         if (dist_sq > 0 and dist_sq < separation_radius_sq) {
    //             const distance = @sqrt(dist_sq);
    //             const difference = self.position
    //                 .subtract(other.position)
    //                 .normalize()
    //                 .scale(1.0 / distance);
    //             steer = steer.add(difference);
    //             count += 1.0;
    //         }
    //     }
    //
    //     if (count > 0.0) {
    //         steer = steer
    //             .scale(1.0 / count)
    //             .normalize()
    //             .scale(self.maxSpeed)
    //             .subtract(self.velocity);
    //         steer = vector2Limit(steer, self.maxForce);
    //     }
    //
    //     return steer;
    // }

    // fn alignment(self: *const Self, all_boids: []const Boid, nearby_indices: []const usize) rl.Vector2 {
    //     var sum = rl.Vector2.zero();
    //     var count: f32 = 0.0;
    //     const alignment_radius_sq = self.alignmentRadius * self.alignmentRadius;
    //
    //     for (nearby_indices) |boid_idx| {
    //         const other = &all_boids[boid_idx];
    //         const dist_sq = distanceSquared(self.position, other.position);
    //         if (dist_sq > 0 and dist_sq < alignment_radius_sq) {
    //             sum = sum.add(other.velocity);
    //             count += 1.0;
    //         }
    //     }
    //
    //     if (count > 0.0) {
    //         sum = sum
    //             .scale(1.0 / count)
    //             .normalize()
    //             .scale(self.maxSpeed);
    //         var steer = sum.subtract(self.velocity);
    //         steer = vector2Limit(steer, self.maxForce);
    //         return steer;
    //     } else {
    //         return rl.Vector2.zero();
    //     }
    // }

    // fn cohesion(self: *const Self, all_boids: []const Boid, nearby_indices: []const usize) rl.Vector2 {
    //     var sum = rl.Vector2.zero();
    //     var count: f32 = 0.0;
    //     const cohesion_radius_sq = self.cohesionRadius * self.cohesionRadius;
    //
    //     for (nearby_indices) |boid_idx| {
    //         const other = &all_boids[boid_idx];
    //         const dist_sq = distanceSquared(self.position, other.position);
    //         if (dist_sq > 0 and dist_sq < cohesion_radius_sq) {
    //             sum = sum.add(other.position);
    //             count += 1.0;
    //         }
    //     }
    //
    //     if (count > 0.0) {
    //         sum = sum.scale(1.0 / count);
    //         return self.seek(sum);
    //     } else {
    //         return rl.Vector2.zero();
    //     }
    // }

    fn seek(self: *const Self, target: rl.Vector2, self_pos: rl.Vector2, self_vel: rl.Vector2) rl.Vector2 {
        const desired = target
            .subtract(self_pos)
            .normalize()
            .scale(self.maxSpeed);

        var steer = desired.subtract(self_vel);
        steer = vector2Limit(steer, self.maxForce);
        return steer;
    }

    // ----------------
    // Util funcs:
    // * update
    // * draw/drawDebug
    // * wrapAround
    // * apply force
    // * mouseAttract
    // ----------------

    pub fn applyUpdate(self: *Self) void {
        // Basic vel/accel/pos updates
        self.velocity = self.velocity.add(self.acceleration);
        self.velocity = vector2Limit(self.velocity, self.maxSpeed);
        self.position = self.position.add(self.velocity);
        self.acceleration = rl.Vector2.zero();

        // Special handling (wall behavior, mouse interactions)
        // self.mouseAttract();
        self.wrapAround();
        // self.bounceOffWall();
    }

    // FIX: bounceOffWall crashes
    fn bounceOffWall(self: *Self) void {
        _ = self;
        @compileError("bounceOffWall called! It crashes!\n");
        // const width = settings.WindowConfig.WIDTH;
        // const height = settings.WindowConfig.HEIGHT;
        // const boundary_thresh = 25.0;
        // if (self.position.x + self.acceleration.x >= width - boundary_thresh)
        //     self.acceleration = rl.Vector2{ .x = -self.acceleration.x, .y = self.acceleration.y };
        // if (self.position.y + self.acceleration.y >= width - boundary_thresh)
        //     self.acceleration = rl.Vector2{ .x = self.acceleration.x, .y = -self.acceleration.y };
    }

    fn wrapAround(self: *Self) void {
        const width = settings.WindowConfig.WIDTH;
        const height = settings.WindowConfig.HEIGHT;

        if (self.position.x < 0) self.position.x = width;
        if (self.position.x > width) self.position.x = 0;
        if (self.position.y < 0) self.position.y = height;
        if (self.position.y > height) self.position.y = 0;
    }

    pub fn draw(self: *const Self) void {
        // TODO: Figure out how to use @tan and @Vector builtins
        const ang = std.math.atan2(self.velocity.y, self.velocity.x);
        const half = self.size * 0.5;

        const tip_offset = rl.Vector2{ .x = self.size, .y = 0 };
        const left_offset = rl.Vector2{ .x = -half, .y = -half };
        const right_offset = rl.Vector2{ .x = -half, .y = half };

        const cos_a = @cos(ang);
        const sin_a = @sin(ang);

        const tip = rl.Vector2{
            .x = self.position.x + (tip_offset.x * cos_a - tip_offset.y * sin_a),
            .y = self.position.y + (tip_offset.x * sin_a + tip_offset.y * cos_a),
        };
        const left = rl.Vector2{
            .x = self.position.x + (left_offset.x * cos_a - left_offset.y * sin_a),
            .y = self.position.y + (left_offset.x * sin_a + left_offset.y * cos_a),
        };
        const right = rl.Vector2{
            .x = self.position.x + (right_offset.x * cos_a - right_offset.y * sin_a),
            .y = self.position.y + (right_offset.x * sin_a + right_offset.y * cos_a),
        };

        rl.drawTriangleLines(tip, left, right, self.color);

        // Pixel test for fps improvements
        // rl.drawPixelV(self.position, self.color);
    }

    pub fn drawDebug(self: *const Self, debug_option: DebugOptions) void {
        self.draw();

        switch (debug_option) {
            .none => {},
            .separation_radius => {
                rl.drawCircleLines(
                    @intFromFloat(self.position.x),
                    @intFromFloat(self.position.y),
                    self.separationRadius,
                    rl.Color.red,
                );
            },
            .alignment_radius => {
                rl.drawCircleLines(
                    @intFromFloat(self.position.x),
                    @intFromFloat(self.position.y),
                    self.alignmentRadius,
                    rl.Color.blue,
                );
            },
            .velocity_vector => {
                const vel_end = self.position.add(self.velocity.scale(10.0));
                rl.drawLine(
                    @intFromFloat(self.position.x),
                    @intFromFloat(self.position.y),
                    @intFromFloat(vel_end.x),
                    @intFromFloat(vel_end.y),
                    rl.Color.green,
                );
            },
            .all => {
                rl.drawCircleLines(
                    @intFromFloat(self.position.x),
                    @intFromFloat(self.position.y),
                    self.separationRadius,
                    rl.Color.red,
                );
                rl.drawCircleLines(
                    @intFromFloat(self.position.x),
                    @intFromFloat(self.position.y),
                    self.alignmentRadius,
                    rl.Color.blue,
                );
                const vel_end = self.position.add(self.velocity.scale(10.0));
                rl.drawLine(
                    @intFromFloat(self.position.x),
                    @intFromFloat(self.position.y),
                    @intFromFloat(vel_end.x),
                    @intFromFloat(vel_end.y),
                    rl.Color.green,
                );
            },
        }
    }

    pub fn mouseAttract(self: *Self) void {
        const mousePos = rl.getMousePosition();
        const distance = self.position.distance(mousePos);
        const attractReject_radius: f32 = 200.0;
        const attractReject_forceScale: f32 = 3.0;

        if (distance < attractReject_radius) {
            const force = self.seek(mousePos).scale(attractReject_forceScale);
            self.acceleration = self.acceleration.add(force);
        }

        rl.drawCircleLinesV(
            mousePos,
            attractReject_radius,
            rl.Color.gold,
        );
    }
};
