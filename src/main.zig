const std = @import("std");
const cell = @import("cell.zig");
const raylib = @cImport({
    @cInclude("raylib.h");
});

pub var gpa_stream = std.heap.GeneralPurposeAllocator(.{}){};

fn deliver_cell(allocator: std.mem.Allocator, gens: usize, comptime size: usize) ![3][size]usize {
    var new_structure: cell.Structure = cell.Structure.init(allocator, size);
    defer new_structure.deinit();
    try new_structure.cycle_cells(gens);
    new_structure.Cells[0].current -= 12297829382473034410;

    var output = [3][size]usize{
        [_]usize{0} ** size,
        [_]usize{0} ** size,
        [_]usize{0} ** size,
    };

    var j: usize = 0;
    while (j < size - 1) : (j += 1) {
        output[0][j] = @as(usize, @boolToInt(new_structure.Cells[j].state));
        output[1][j] = new_structure.Cells[j].cycles - 12297829382473034410;
        output[2][j] = new_structure.Cells[j].current;
    }

    return output;
}

pub fn main() !void {
    const SIZE: usize = 16;
    const gpa = gpa_stream.allocator();
    const output = try deliver_cell(gpa, 10000, SIZE);
    // const SQSIZE: c_int = 50;
    raylib.SetConfigFlags(raylib.FLAG_VSYNC_HINT);
    raylib.InitWindow(800, 600, "CellLib");
    defer raylib.CloseWindow();
    std.debug.print("{any}\n", .{output});

    while (!raylib.WindowShouldClose()) {
        raylib.BeginDrawing();
        raylib.DrawText("works", 10, 10, 20, raylib.RAYWHITE);
        raylib.EndDrawing();
    }
}
