const std = @import("std");
const rl = @import("raylib");
const settings = @import("settings.zig");
const game = @import("game.zig");
const boids = @import("boids.zig");

pub const SpatialGrid = struct {
    pub const CELL_SIZE: f32 = settings.BoidConfig.CELL_SIZE;
    pub const GRID_WIDTH: usize = @intFromFloat(@ceil(settings.WindowConfig.WIDTH / CELL_SIZE));
    pub const GRID_HEIGHT: usize = @intFromFloat(@ceil(settings.WindowConfig.HEIGHT / CELL_SIZE));
    pub const MAX_BOIDS_PER_CELL: usize = blk: {
        const total_boids = settings.BoidConfig.MAX_BOIDS;
        const total_cells = GRID_HEIGHT * GRID_WIDTH;

        const avg = (total_boids + total_cells - 1) / total_cells;
        const clust_f = 4;

        break :blk @max(64, avg * clust_f);
    };

    const Cell = struct {
        boid_indices: [MAX_BOIDS_PER_CELL]usize,
        boid_count: usize,

        fn clear(self: *Cell) void {
            self.boid_count = 0;
        }

        fn addBoidToCell(self: *Cell, boid_index: usize) void {
            if (self.boid_count < MAX_BOIDS_PER_CELL) {
                self.boid_indices[self.boid_count] = boid_index;
                self.boid_count += 1;
            } else {
                // FIX: Ignoring overflow, exluding additional boids from spatial grid optimization
            }
        }

        fn getBoidIndices(self: *const Cell) []const usize {
            return self.boid_indices[0..self.boid_count];
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
                    .boid_count = 0,
                };
            }
        }

        return grid;
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

    pub fn addBoid(self: *Self, boid_index: usize, position: rl.Vector2) void {
        const coords = getCellCoords(position);
        self.cells[coords.y][coords.x].addBoidToCell(boid_index);
    }

    pub fn getNearbyBoids(self: *Self, position: rl.Vector2, nearby_buf: []usize, nearby_count: *usize) void {
        nearby_count.* = 0;
        const coords = getCellCoords(position);

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
