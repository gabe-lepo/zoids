const std = @import("std");
const rl = @import("raylib");
const settings = @import("settings.zig");

pub const SpatialGrid = struct {
    // PERF:
    // Cell size needs to be limited to the largest flock behavior radius size
    // uncomment compile log in the init to confirm
    pub const CELL_SIZE: f32 = @max(
        settings.BoidConfig.ALIGNMENT_RADIUS * 2.0,
        settings.BoidConfig.COHESION_RADIUS,
        settings.BoidConfig.SEPARATION_RADIUS,
    );
    pub const GRID_WIDTH: usize = @intFromFloat(@ceil(settings.WindowConfig.WIDTH / CELL_SIZE));
    pub const GRID_HEIGHT: usize = @intFromFloat(@ceil(settings.WindowConfig.HEIGHT / CELL_SIZE));
    const MAX_BOIDS_PER_CELL: usize = 64;

    // Fixed arrays instead of arraylists
    const Cell = struct {
        boid_indices: [MAX_BOIDS_PER_CELL]usize,
        count: usize,

        fn clear(self: *Cell) void {
            self.count = 0;
        }

        fn addBoid(self: *Cell, boid_index: usize) !void {
            if (self.count >= MAX_BOIDS_PER_CELL) {
                // FIX: We reach this condition way too often
                std.debug.print("Cant add boid! Count: {d} more than MAX_BOIDS_PER_CELL: {d}\n", .{ self.count, MAX_BOIDS_PER_CELL });
                return error.CellOverflow;
            }
            self.boid_indices[self.count] = boid_index;
            self.count += 1;
        }

        fn getBoidIndices(self: *const Cell) []const usize {
            return self.boid_indices[0..self.count];
        }
    };

    cells: [GRID_HEIGHT][GRID_WIDTH]Cell,

    const Self = @This();

    pub fn init() Self {
        // @compileLog(CELL_SIZE);
        var grid = Self{
            .cells = undefined,
        };

        // Init all cells
        for (0..GRID_HEIGHT) |y| {
            for (0..GRID_WIDTH) |x| {
                grid.cells[y][x] = Cell{
                    .boid_indices = undefined,
                    .count = 0,
                };
            }
        }

        return grid;
    }

    pub fn deinit(self: *Self) void {
        _ = self;
        @compileError("SpatialGrid.deinit is deprecated!\n");

        // for (0..GRID_HEIGHT) |y| {
        //     for (0..GRID_WIDTH) |x| {
        //         self.cells[y][x].deinit(self.allocator);
        //     }
        // }
    }

    pub fn clear(self: *Self) void {
        for (0..GRID_HEIGHT) |y| {
            for (0..GRID_WIDTH) |x| {
                self.cells[y][x].clear();
            }
        }
    }

    fn getCellCoords(pos: rl.Vector2) struct { x: usize, y: usize } {
        const x = @min(GRID_WIDTH - 1, @max(0, @as(usize, @intFromFloat(pos.x / CELL_SIZE))));
        const y = @min(GRID_HEIGHT - 1, @max(0, @as(usize, @intFromFloat(pos.y / CELL_SIZE))));
        return .{ .x = x, .y = y };
    }

    pub fn addBoid(self: *Self, boid_index: usize, position: rl.Vector2) !void {
        const coords = getCellCoords(position);
        try self.cells[coords.y][coords.x].addBoid(boid_index);
    }

    pub fn getNearbyBoids(self: *Self, position: rl.Vector2, nearby_buf: []usize, nearby_count: *usize) void {
        nearby_count.* = 0;
        const coords = getCellCoords(position);

        // Check curr cell and 8 neighbors
        const start_y: i32 = @max(0, @as(i32, @intCast(coords.y)) - 1);
        const end_y: i32 = @min(@as(i32, @intCast(GRID_HEIGHT)) - 1, @as(i32, @intCast(coords.y)) + 1);
        const start_x: i32 = @max(0, @as(i32, @intCast(coords.x)) - 1);
        const end_x: i32 = @min(@as(i32, @intCast(GRID_WIDTH)) - 1, @as(i32, @intCast(coords.x)) + 1);

        var y: i32 = start_y;
        while (y <= end_y) : (y += 1) {
            var x: i32 = start_x;
            while (x <= end_x) : (x += 1) {
                const cell = &self.cells[@intCast(y)][@intCast(x)];
                const indices = cell.getBoidIndices();

                for (indices) |boid_index| {
                    if (nearby_count.* < nearby_buf.len) {
                        nearby_buf[nearby_count.*] = boid_index;
                        nearby_count.* += 1;
                    }
                }
            }
        }
    }
};
