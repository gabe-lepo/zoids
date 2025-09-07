const std = @import("std");
const rl = @import("raylib");
const settings = @import("settings.zig");

pub const SpatialGrid = struct {
    const CELL_SIZE: f32 = 80.0;
    const GRID_WIDTH: usize = @intFromFloat(@ceil(settings.WindowConfig.WIDTH / CELL_SIZE));
    const GRID_HEIGHT: usize = @intFromFloat(@ceil(settings.WindowConfig.HEIGHT / CELL_SIZE));

    // Each cell has indices to boids in the same cell
    cells: [GRID_HEIGHT][GRID_WIDTH]std.ArrayList(usize),
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) !Self {
        var grid = Self{
            .cells = undefined,
            .allocator = allocator,
        };

        // Init cells
        for (0..GRID_HEIGHT) |y| {
            for (0..GRID_WIDTH) |x| {
                grid.cells[y][x] = try std.ArrayList(usize).initCapacity(allocator, 8);
            }
        }

        return grid;
    }

    pub fn deinit(self: *Self) void {
        for (0..GRID_HEIGHT) |y| {
            for (0..GRID_WIDTH) |x| {
                self.cells[y][x].deinit(self.allocator);
            }
        }
    }

    pub fn clear(self: *Self) void {
        for (0..GRID_HEIGHT) |y| {
            for (0..GRID_WIDTH) |x| {
                self.cells[y][x].clearRetainingCapacity();
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
        try self.cells[coords.y][coords.x].append(self.allocator, boid_index);
    }

    pub fn getNearbyBoids(self: *Self, position: rl.Vector2, nearby_indices: *std.ArrayList(usize)) !void {
        nearby_indices.clearRetainingCapacity();
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
                for (cell.items) |boid_index| {
                    try nearby_indices.append(self.allocator, boid_index);
                }
            }
        }
    }
};
