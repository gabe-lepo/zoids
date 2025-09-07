const rl = @import("raylib");
const utils = @import("utils.zig");
const settings = @import("settings.zig");

pub const Shapes = union(enum) {
    rectangle: rl.Rectangle,
    circle: struct {
        center: rl.Vector2,
        radius: f32,
    },
    triangle: struct {
        v1: rl.Vector2,
        v2: rl.Vector2,
        v3: rl.Vector2,
    },
};

pub const Player = struct {
    // Basic properties
    position: rl.Vector2,
    center: rl.Vector2,
    shape: Shapes,
    collideable: bool,
    color: rl.Color,
    label: [:0]const u8,

    // Basic movement
    velocity: rl.Vector2,
    terminal_velocity: rl.Vector2,
    move_speed: f32,
    sprint_speed_mod: f32,
    sneak_speed_mod: f32,

    // Jumping
    isGrounded: bool,
    gravity: f32,
    jump_speed: f32,
    max_jump_height: f32,
    max_jumps: u8,
    remaining_jumps: u8,

    pub fn init() Player {
        const position = rl.Vector2.zero();
        const width: f32 = 128;
        const height: f32 = 128;
        const center = rl.Vector2{
            .x = (position.x + (0.5 * width)),
            .y = (position.y + (0.5 * height)),
        };
        const player_color = utils.Colors.initFromRGB(utils.Colors.RGB{
            .r = settings.BACKGROUND_COLOR.r,
            .g = settings.BACKGROUND_COLOR.g,
            .b = settings.BACKGROUND_COLOR.b,
            .a = settings.BACKGROUND_COLOR.a,
        }).complimentary();

        return Player{
            .position = position,
            .center = center,
            .shape = Shapes{
                .rectangle = rl.Rectangle{
                    .x = position.x,
                    .y = position.y,
                    .width = width,
                    .height = height,
                },
            },
            .collideable = true,
            .color = player_color,
            .label = "Player",

            .velocity = rl.Vector2.zero(),
            .terminal_velocity = rl.Vector2{ .x = 50, .y = 15 },
            .move_speed = 3.5,
            .sprint_speed_mod = 2,
            .sneak_speed_mod = 0,

            .isGrounded = true,
            .gravity = 10.0,
            .jump_speed = 12,
            .max_jump_height = height * 2,
            .max_jumps = 2,
            .remaining_jumps = 2,
        };
    }

    pub fn update(player: *Player) void {
        // Logic that depends on grounded state
        if (player.isGrounded) {
            player.remaining_jumps = player.max_jumps;
            player.velocity.y = 0;
        } else {
            // Apply gravity if not at terminal_velocity
            if (player.velocity.y < player.terminal_velocity.y) {
                player.velocity.y += player.gravity;
            } else {
                player.velocity.y = player.terminal_velocity.y;
            }

            // Apply vertical movement depending on shape
            switch (player.shape) {
                .rectangle => |*rect| {
                    rect.y += player.velocity.y;
                },
                .circle => |*circ| {
                    circ.center.y += player.velocity.y;
                },
                .triangle => |*tri| {
                    tri.v1.y += player.velocity.y;
                    tri.v2.y += player.velocity.y;
                    tri.v3.y += player.velocity.y;
                },
            }
        }

        // Non-grounding related logic
        // Reset move speed each frame
        player.move_speed = 3.5;
        player.velocity.x = 0;

        // Sprinting
        if (rl.isKeyDown(rl.KeyboardKey.left_shift) or rl.isKeyDown(rl.KeyboardKey.right_shift)) {
            player.move_speed *= player.sprint_speed_mod;
        }

        // Sneaking
        if (rl.isKeyDown(rl.KeyboardKey.left_control) or rl.isKeyDown(rl.KeyboardKey.right_control)) {
            player.move_speed *= player.sneak_speed_mod;
        }

        // Basic arrow key movement
        if (rl.isKeyDown(rl.KeyboardKey.right)) {
            player.velocity.x = player.move_speed;
        }
        if (rl.isKeyDown(rl.KeyboardKey.left)) {
            player.velocity.x = -player.move_speed;
        }

        // Jumping
        if (rl.isKeyDown(rl.KeyboardKey.space)) {
            if (player.remaining_jumps > 0) {
                player.isGrounded = false;
                player.velocity.y = -player.jump_speed;
                player.remaining_jumps -= 1;
            }
        }

        // Apply horizontal movement depending on shape
        switch (player.shape) {
            .rectangle => |*rect| {
                rect.x += player.velocity.x;
            },
            .circle => |*circ| {
                circ.center.x += player.velocity.x;
            },
            .triangle => |*tri| {
                tri.v1.x += player.velocity.x;
                tri.v2.x += player.velocity.x;
                tri.v3.x += player.velocity.x;
            },
        }
    }

    pub fn draw(player: Player) void {
        // Label things
        const textSize: f32 = 20;
        const textWidth = @as(
            f32,
            @floatFromInt(rl.measureText(player.label, textSize)),
        );
        var labelPosition = rl.Vector2.zero();

        // Draw the player shape
        switch (player.shape) {
            .rectangle => |rect| {
                rl.drawRectangleRec(rect, player.color);
                labelPosition.x = rect.x + (rect.width * 0.5) - (textWidth * 0.5);
                labelPosition.y = rect.y + (rect.height * 0.5) - (textSize * 0.5);
            },
            .circle => |circ| {
                rl.drawCircleV(circ.center, circ.radius, player.color);
                labelPosition.x = circ.center.x - (textWidth * 0.5);
                labelPosition.y = circ.center.y - (textSize * 0.5);
            },
            .triangle => |tri| {
                rl.drawTriangle(tri.v1, tri.v2, tri.v3, player.color);
                const center = rl.Vector2{
                    .x = (tri.v1.x + tri.v2.x + tri.v3.x) / 3,
                    .y = (tri.v1.y + tri.v2.y + tri.v3.y) / 3,
                };
                labelPosition.x = center.x - (textWidth * 0.5);
                labelPosition.y = center.y - (textSize * 0.5);
            },
        }

        // Draw label
        const label_color = utils.Colors.initFromRGB(utils.Colors.RGB{
            .r = player.color.r,
            .g = player.color.g,
            .b = player.color.b,
            .a = player.color.a,
        }).complimentary();

        rl.drawText(
            player.label,
            @as(i32, @intFromFloat(labelPosition.x)),
            @as(i32, @intFromFloat(labelPosition.y)),
            textSize,
            label_color,
        );
    }
};
