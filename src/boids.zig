const std = @import("std");
const rl = @import("raylib");
const settings = @import("settings.zig");

var global_rng: std.Random.DefaultPrng = undefined;
var rng_init: bool = false;

// Helpers
fn initRng() void {
    if (!rng_init) {
        var seed: u64 = undefined;
        std.posix.getrandom(std.mem.asBytes(&seed)) catch |e| {
            std.debug.print("std.posix.getrandom error:\n\t{any}\n", .{e});
            std.debug.print("Using current timestamp for seed!\n", .{});
            seed = @intCast(std.time.timestamp());
        };
        global_rng = std.Random.DefaultPrng.init(seed);
        rng_init = true;
    }
}

pub fn getRng() std.Random {
    initRng();
    return global_rng.random();
}

fn vector2Limit(vec: rl.Vector2, maxMagnitude: f32) rl.Vector2 {
    const mag = vec.length();
    return if (mag > maxMagnitude) vec.normalize().scale(maxMagnitude) else vec;
}

fn vector2Random() rl.Vector2 {
    var rng = getRng();

    return rl.Vector2{
        // Vec of rand [-2..2]
        .x = rng.float(f32) * 4.0 - 2.0,
        .y = rng.float(f32) * 4.0 - 2.0,
    };
}

// Debug options
pub const DebugOptions = enum {
    none,
    separation_radius,
    alignment_radius,
    velocity_vector,
    all,
};

// Meat and potatoes
pub const Boid = struct {
    // Core
    position: rl.Vector2,
    velocity: rl.Vector2,
    acceleration: rl.Vector2,
    maxSpeed: f32 = 2.5,
    maxForce: f32 = 0.04,

    // Behavior radii
    separationRadius: f32 = 32.0,
    alignmentRadius: f32 = 64.0,
    cohesionRadius: f32 = 64.0,

    // Behavior weighting
    separationWeight: f32 = 1.5,
    alignmentWeight: f32 = 1.0,
    cohesionWeight: f32 = 1.0,

    // Visual props
    size: f32 = 8.0,
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
        var rng = getRng();

        return Self.initSpecific(rl.Vector2{
            .x = rng.float(f32) * @as(f32, @floatFromInt(settings.WINDOW_WIDTH)),
            .y = rng.float(f32) * @as(f32, @floatFromInt(settings.WINDOW_HEIGHT)),
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

    pub fn flock(self: *Self, boids: []const Boid) void {
        const sep = self.separate(boids);
        const ali = self.alignment(boids);
        const coh = self.cohesion(boids);

        self.acceleration = self.acceleration
            .add(sep.scale(self.separationWeight))
            .add(ali.scale(self.alignmentWeight))
            .add(coh.scale(self.cohesionWeight));
    }

    fn separate(self: *const Self, boids: []const Boid) rl.Vector2 {
        var steer = rl.Vector2.zero();
        var count: i32 = 0;

        for (boids) |other| {
            const distance = self.position.distance(other.position);
            if (distance > 0 and distance < self.separationRadius) {
                var difference = self.position.subtract(other.position);
                difference = difference.normalize();
                difference = difference.scale(1.0 / distance);
                steer = steer.add(difference);
                count += 1;
            }
        }

        if (count > 0) {
            steer = steer
                .scale(1.0 / @as(f32, @floatFromInt(count)))
                .normalize()
                .scale(self.maxSpeed)
                .subtract(self.velocity);
            steer = vector2Limit(steer, self.maxForce);
        }

        return steer;
    }

    fn alignment(self: *const Self, boids: []const Boid) rl.Vector2 {
        var sum = rl.Vector2.zero();
        var count: i32 = 0;

        for (boids) |other| {
            const distance = self.position.distance(other.position);
            if (distance > 0 and distance < self.alignmentRadius) {
                sum = sum.add(other.velocity);
                count += 1;
            }
        }

        if (count > 0) {
            sum = sum
                .scale(1.0 / @as(f32, @floatFromInt(count)))
                .normalize()
                .scale(self.maxSpeed);
            var steer = sum.subtract(self.velocity);
            steer = vector2Limit(steer, self.maxForce);
            return steer;
        } else {
            return rl.Vector2.zero();
        }
    }

    fn cohesion(self: *const Self, boids: []const Boid) rl.Vector2 {
        var sum = rl.Vector2.zero();
        var count: i32 = 0;

        for (boids) |other| {
            const distance = self.position.distance(other.position);
            if (distance > 0 and distance < self.cohesionRadius) {
                sum = sum.add(other.position);
                count += 1;
            }
        }

        if (count > 0) {
            sum = sum.scale(1.0 / @as(f32, @floatFromInt(count)));
            return self.seek(sum);
        } else {
            return rl.Vector2.zero();
        }
    }

    fn seek(self: *const Self, target: rl.Vector2) rl.Vector2 {
        var desired = target
            .subtract(self.position)
            .normalize()
            .scale(self.maxSpeed);

        var steer = desired.subtract(self.velocity);
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

    pub fn update(self: *Self) void {
        self.velocity = self.velocity.add(self.acceleration);
        self.velocity = vector2Limit(self.velocity, self.maxSpeed);
        self.position = self.position.add(self.velocity);
        self.acceleration = rl.Vector2.zero();

        self.mouseAttract();
        self.wrapAround();
    }

    fn wrapAround(self: *Self) void {
        const width = @as(f32, @floatFromInt(settings.WINDOW_WIDTH));
        const height = @as(f32, @floatFromInt(settings.WINDOW_HEIGHT));

        if (self.position.x < 0) self.position.x = width;
        if (self.position.x > width) self.position.x = 0;
        if (self.position.y < 0) self.position.y = height;
        if (self.position.y > height) self.position.y = 0;
    }

    pub fn draw(self: *const Self) void {
        const ang = std.math.atan2(self.velocity.y, self.velocity.x);
        const half = self.size * 0.5;

        const tip_offset = rl.Vector2{ .x = self.size, .y = 0 };
        const left_offset = rl.Vector2{ .x = -half, .y = -half };
        const right_offset = rl.Vector2{ .x = -half, .y = half };

        const cos_a = std.math.cos(ang);
        const sin_a = std.math.sin(ang);

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

    pub fn applyForce(self: *Self, force: rl.Vector2) void {
        self.acceleration = self.acceleration.add(force);
    }

    pub fn mouseAttract(self: *Self) void {
        const mousePos = rl.getMousePosition();
        const distance = self.position.distance(mousePos);
        const attractReject_radius: f32 = 200.0;
        const attractReject_forceScale: f32 = 3.0;

        if (distance < attractReject_radius) {
            const force = self.seek(mousePos).scale(attractReject_forceScale);
            self.applyForce(force);
        }

        rl.drawCircleLinesV(mousePos, attractReject_radius, rl.Color.gold);
    }
};
