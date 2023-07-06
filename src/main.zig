const std = @import("std");
const cell = @import("cell.zig");
const raylib = @cImport({
    @cInclude("raylib.h");
});

pub var gpa_stream = std.heap.GeneralPurposeAllocator(.{}){};

/// cycle flatte () flattens the cycle of structure into three array outups
/// @param { cell.Structure } Structure to cycle
/// @param { usize } size of structure (n of cells)
/// @returns [3][size]usize array of flat struct
/// 0 state
/// 1 current
/// 2 cycles
fn cycle_flatten(map: *cell.Structure, comptime size: usize, cycles: usize) [3][size]usize {
    map.simulate(cycles) catch {
        @panic("cycle failed");
    };

    // if (map.Cells[0].current == 0) {
    //     map.Cells[0].current -= 1;
    // }
    var output = [3][size]usize{
        [_]usize{0} ** size,
        [_]usize{0} ** size,
        [_]usize{0} ** size,
    };

    var j: usize = 0;
    while (j < size - 1) : (j += 1) {
        // if (map.Cells[j].current == 12297829382473034410) {
        //     map.Cells[j].current -= 12297829382473034410;
        // }
        // if (map.Cells[j].cycles == 12297829382473034411) {
        // map.Cells[j].cycles -= 12297829382473034410;
        // }
        output[0][j] = @as(usize, @boolToInt(map.Cells[j].state));
        output[1][j] = map.Cells[j].current;
        output[2][j] = map.Cells[j].cycles - 12297829382473034410;
    }

    return output;
}

/// grid () generates a raylib Rectangle array of size size
/// so that DrawRectangle can be called.
/// @param { usize } size: number of rectangles
/// @param { f32 } wh: square width of rectangles
/// @returns array of rectangles structs
fn grid(comptime size: usize, comptime wh: f32) [size]raylib.Rectangle {
    var row = @intToFloat(f32, std.math.sqrt(size));
    var rectangles: [size]raylib.Rectangle = undefined;
    var iterator: usize = 0;
    while (iterator < size) : (iterator += 1) {
        var i = @intToFloat(f32, iterator);
        rectangles[iterator].x = 20 + (wh * @mod(i, row));
        rectangles[iterator].y = 80 + (wh * (i / row));
        rectangles[iterator].width = wh;
        rectangles[iterator].height = wh;
    }

    return rectangles;
}

pub fn main() !void {

    // constants
    const SQ: c_int = 14;
    const SIZE: usize = SQ * SQ;
    const ROWS = 800;
    const COLS = 600;
    const GEN_ITER = 10;
    const WH = 3 * SQ;
    const gpa = gpa_stream.allocator();
    var rectangles = grid(SIZE, WH);
    var current_generation: c_int = 1;
    // end constants

    // generations
    var map: cell.Structure = cell.Structure.init(gpa, SIZE);
    _ = try map.shuffle_cells();
    var output = cycle_flatten(&map, SIZE, 1);
    defer map.deinit();
    // end generations

    // window
    raylib.SetConfigFlags(raylib.FLAG_VSYNC_HINT | raylib.FLAG_WINDOW_RESIZABLE);
    raylib.InitWindow(ROWS, COLS, "CellLib");
    defer raylib.CloseWindow();
    // end window

    while (!raylib.WindowShouldClose()) {
        raylib.BeginDrawing();
        raylib.ClearBackground(raylib.BLACK);
        defer raylib.EndDrawing();

        raylib.DrawText(raylib.TextFormat("Cell Visualations   gen : %i", current_generation), (ROWS / 3) - 100, 20, 50, raylib.RAYWHITE);
        // raylib.DrawText(raylib.TextFormat(" Generation: %i", current_generation), (ROWS / 3) - 15, 50, 15, raylib.RAYWHITE);
        for (0..SIZE) |i| {
            var colour = raylib.BLUE;
            if (output[0][i] == 0) {
                colour = raylib.RED;
            }
            const x_pos = @floatToInt(c_int, rectangles[i].x + (COLS / 4));
            const y_pos = @floatToInt(c_int, (rectangles[i].y - rectangles[i].height + 50));
            raylib.DrawRectangle(x_pos, y_pos, @floatToInt(c_int, rectangles[i].width), @floatToInt(c_int, rectangles[i].height), colour);
            raylib.DrawText(raylib.TextFormat("%i", output[2][i]), x_pos + SQ, y_pos + SQ, 20, raylib.BLACK);
            // raylib.DrawText(raylib.TextFormat("r %i", output[1][i]), x_pos + SQ, y_pos + SQ + SQ, 18, raylib.BLACK);
            // std.debug.print("curr {} cycles {}\n", .{ output[1][i], output[2][i] });
        }

        if (raylib.IsKeyPressed(raylib.KEY_SPACE)) {
            output = cycle_flatten(&map, SIZE, GEN_ITER);
            current_generation += GEN_ITER;
            raylib.ClearBackground(raylib.BLACK);
        }
    }
}
