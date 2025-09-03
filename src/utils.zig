const std = @import("std");
const rl = @import("raylib");

pub const Colors = struct {
    // Types
    pub const HSL = struct {
        h: f32,
        s: f32,
        l: f32,
        a: f32,
    };

    pub const RGB = rl.Color;

    // Instance data
    rgb: RGB,
    hsl: HSL,
    prng_global: ?std.Random.DefaultPrng = null,

    // Constructors
    pub fn initFromRGB(rgb: RGB) Colors {
        var colors = Colors{
            .rgb = rgb,
            .hsl = undefined,
        };
        colors.hsl = colors.rgbToHsl();
        return colors;
    }

    pub fn initFromHSL(hsl: HSL) Colors {
        var colors = Colors{
            .rgb = undefined,
            .hsl = hsl,
        };
        colors.rgb = colors.hslToRgb();
        return colors;
    }

    pub fn initRandom(min: u8, max: u8, alpha: u8) Colors {
        var colors = Colors{
            .rgb = undefined,
            .hsl = undefined,
        };
        colors.rgb = colors.generateRandom(min, max, alpha);
        colors.hsl = colors.rgbToHsl();
        return colors;
    }

    // Methods
    pub fn rgbToHsl(self: *const Colors) HSL {
        const r: f32 = @as(f32, @floatFromInt(self.rgb.r)) / 255.0;
        const g: f32 = @as(f32, @floatFromInt(self.rgb.g)) / 255.0;
        const b: f32 = @as(f32, @floatFromInt(self.rgb.b)) / 255.0;
        const a: f32 = @as(f32, @floatFromInt(self.rgb.a));

        const min_val: f32 = @min(r, @min(g, b));
        const max_val: f32 = @max(r, @max(g, b));
        const delta: f32 = max_val - min_val;

        var result = HSL{
            .h = 0.0,
            .s = 0.0,
            .l = (max_val + min_val) / 2.0,
            .a = a,
        };

        // Hue
        if (delta != 0.0) {
            // Cant switch on non-comptime values (r,g,b,a)
            if (r == max_val) {
                result.h = @mod((g - b) / delta, 6.0);
            } else if (g == max_val) {
                result.h = (b - r) / delta + 2.0;
            } else {
                result.h = (r - g) / delta + 4.0;
            }

            result.h *= 60.0;
            if (result.h < 0.0) result.h += 360.0;
        }

        // Saturation
        if (delta != 0.0) {
            result.s = delta / (1.0 - @abs(2.0 * result.l - 1.0));
        }

        return result;
    }

    pub fn hslToRgb(self: *const Colors) RGB {
        const c: f32 = (1.0 - @abs(2.0 * self.hsl.l - 1.0)) * self.hsl.s;
        const x: f32 = c * (1.0 - @abs(@mod(self.hsl.h / 60.0, 2.0) - 1.0));
        const m = self.hsl.l - c / 2.0;

        var r: f32 = 0.0;
        var g: f32 = 0.0;
        var b: f32 = 0.0;

        if (self.hsl.h >= 0 and self.hsl.h < 60) {
            r = c;
            g = x;
            b = 0;
        } else if (self.hsl.h >= 60 and self.hsl.h < 120) {
            r = x;
            g = c;
            b = 0;
        } else if (self.hsl.h >= 120 and self.hsl.h < 180) {
            r = 0;
            g = c;
            b = x;
        } else if (self.hsl.h >= 180 and self.hsl.h < 240) {
            r = 0;
            g = x;
            b = c;
        } else if (self.hsl.h >= 240 and self.hsl.h < 300) {
            r = x;
            g = 0;
            b = c;
        } else {
            r = c;
            g = 0;
            b = x;
        }

        return RGB{
            .r = @intFromFloat((r + m) * 255.0),
            .g = @intFromFloat((g + m) * 255.0),
            .b = @intFromFloat((b + m) * 255.0),
            .a = @intFromFloat(self.hsl.a),
        };
    }

    pub fn updateFromRGB(self: *Colors, new: RGB) void {
        self.rgb = new;
        self.hsl = self.rgbToHsl();
    }

    pub fn updateFromHSL(self: *Colors, new: HSL) void {
        self.hsl = new;
        self.rgb = self.hslToRgb();
    }

    pub fn generateRandom(self: *Colors, min: u8, max: u8, alpha: u8) RGB {
        if (self.prng_global == null) {
            var seed: u64 = undefined;
            std.posix.getrandom(std.mem.asBytes(&seed)) catch {
                seed = @intCast(std.time.timestamp());
            };
            self.prng_global = std.Random.DefaultPrng.init(seed);
        }

        const rand = self.prng_global.?.random();
        return RGB{
            .r = rand.intRangeAtMost(u8, min, max),
            .g = rand.intRangeAtMost(u8, min, max),
            .b = rand.intRangeAtMost(u8, min, max),
            .a = alpha,
        };
    }

    pub fn setRandom(self: *Colors, min: u8, max: u8, alpha: u8) void {
        self.rgb = self.generateRandom(min, max, alpha);
        self.hsl = self.rgbToHsl();
    }

    pub fn complimentary(self: *const Colors) RGB {
        return RGB{
            .r = 255 - self.rgb.r,
            .g = 255 - self.rgb.g,
            .b = 255 - self.rgb.b,
            .a = self.rgb.a,
        };
    }

    pub fn analogous(self: *Colors, hueShift: f32) RGB {
        self.hsl.h += hueShift;
        self.hsl.h = @mod(self.hsl.h + 360.0, 360.0);

        self.rgb = self.hslToRgb();
        return self.rgb;
    }

    pub fn triadic(self: *const Colors) struct { base: RGB, color1: RGB, color2: RGB } {
        // HSL copies with +120 and -120 degree shifts
        var hsl1 = self.hsl;
        var hsl2 = self.hsl;

        hsl1.h = @mod(self.hsl.h + 120.0, 360.0);
        hsl2.h = @mod(self.hsl.h - 120.0 + 360.0, 360.0);

        return .{
            .base = self.rgb,
            .color1 = Colors.initFromHSL(hsl1).rgb,
            .color2 = Colors.initFromHSL(hsl2).rgb,
        };
    }

    pub fn blend(color1: RGB, color2: RGB, factor: f32) RGB {
        // Clamp and normalize
        const t = @max(0.0, @min(1.0, factor));

        // Type casting in zig is... kind of annoying. Here's a helper fn
        const blend_component = struct {
            fn blend(a: u8, b: u8, f: f32) u8 {
                const af = @as(f32, @floatFromInt(a));
                const bf = @as(f32, @floatFromInt(b));
                return @intFromFloat(af + f * (bf - af));
            }
        }.blend;

        return RGB{
            .r = blend_component(color1.r, color2.r, t),
            .g = blend_component(color1.g, color2.g, t),
            .b = blend_component(color1.b, color2.b, t),
            .a = blend_component(color1.a, color2.a, t),
        };
    }

    pub fn getContrast(color1: RGB, color2: RGB) f32 {
        // https://en.wikipedia.org/wiki/Rec._709
        const redPerceptionWeight: f32 = 0.2126;
        const greenPerceptionWeight: f32 = 0.7152;
        const bluePerceptionWeight: f32 = 0.0722;

        const luminance1 = redPerceptionWeight * color1.r + greenPerceptionWeight * color1.g + bluePerceptionWeight * color1.b;
        const luminance2 = redPerceptionWeight * color2.r + greenPerceptionWeight * color2.g + bluePerceptionWeight * color2.b;

        var result: f32 = undefined;
        if (luminance1 > luminance2) {
            result = (luminance1 + 0.05) / (luminance2 + 0.05);
        } else {
            result = (luminance2 + 0.05) / (luminance1 + 0.05);
        }

        return result;
    }
};
