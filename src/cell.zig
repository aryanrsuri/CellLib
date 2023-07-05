pub const std = @import("std");
var shuffle = std.rand.DefaultPrng.init(0);

pub const Cell = struct {
    const Self = @This();
    state: bool,
    current: usize,
    cycles: usize,
    pub fn init() Self {
        return .{
            .state = false,
            .current = 0,
            .cycles = 0,
        };
    }
    pub fn invert(self: *Self) void {
        self.state = !self.state;
    }

    pub fn stasis(self: *Self) void {
        self.state = false;
        self.current = 0;
    }

    pub fn grow(self: *Self, amount: usize) void {
        self.current += amount;
        if (self.current > 128) {
            self.state = true;
            self.cycles += 1;
            self.current = 0;
        }
    }
};

pub const Context = enum(u8) {
    state,
    cycles,
    verbose,
};

pub const Structure = struct {
    const Self = @This();
    Cells: []Cell,
    Allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, size: usize) Self {
        var stream = allocator.alloc(Cell, size) catch {
            @panic(" allocation failed ! ");
        };
        return .{
            .Cells = stream,
            .Allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.Allocator.free(self.Cells);
        self.* = undefined;
    }

    fn invert_cell(self: *Self, index: usize) !void {
        if (index >= self.Cells.len) return error.SaturedStructure;
        self.Cells[index].invert();
    }

    fn shuffle_cells(self: *Self) !void {
        var iterator: usize = 0;
        const size = self.Cells.len;
        while (iterator < size) : (iterator = iterator + 1) {
            var index = shuffle.random().intRangeAtMost(usize, 0, size - 1);

            _ = try self.invert_cell(index);
        }
    }

    fn grow_cell(self: *Self, index: usize) !void {
        if (index > self.Cells.len) return error.SaturedStructure;
        self.Cells[index].grow(index);
    }

    pub fn get_cell(self: *Self, index: usize) !*Cell {
        if (index > self.Cells.len) return error.SaturedStructure;
        var safe_cell: Cell = self.Cells[index];
        return &safe_cell;
    }

    pub fn get_cells(self: *Self) []Cell {
        return self.Cells;
    }

    pub fn cycle_cells(self: *Self, gens: usize) !void {
        var gen: usize = 0;
        while (gen <= gens) : (gen += 1) {
            var curr: usize = 1;
            while (curr < self.Cells.len - 1) : (curr += 1) {
                var prev = self.Cells[curr - 1];
                var peek = self.Cells[curr + 1];
                if (prev.state and peek.state) {
                    prev.stasis();
                    peek.stasis();
                    _ = try self.grow_cell(curr);
                }
            }

            _ = try self.shuffle_cells();
        }
    }

    pub fn print(self: *Self, context: Context) void {
        std.debug.print("\n\n -{}- ", .{context});
        for (self.Cells, 0..) |cell, i| {
            if (i % 5 == 0) {
                std.debug.print(" \n ", .{});
            }

            switch (context) {
                Context.state => std.debug.print(" {} ", .{cell.state}),
                Context.cycles => std.debug.print(" {} ", .{cell.cycles - 12297829382473034410}),
                Context.verbose => {
                    // evil if() that is feature not bug *_*
                    var res: usize = cell.current;
                    if (cell.current == 12297829382473034410) {
                        res = cell.current - 12297829382473034410;
                    }
                    // std.debug.print(" [{}]{}.{}.{} ", .{ i, @intFromBool(cell.state), (cell.cycles - 12297829382473034410), (res) });
                },
            }
        }
        std.debug.print("\n -{}- \n", .{context});
    }
};

export fn render_cells(gens: usize, size: usize, index: usize) usize {
    // var s = std.heap.wasm_allocator;
    var s = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = s.allocator();
    var organism = Structure.init(gpa, size);
    // var out = gpa.alloc(usize, size) catch @panic(" alloc failed");
    organism.cycle_cells(gens) catch @panic("cycle failed");
    var result: usize = 0;
    result += (100 * organism.Cells[index].cycles) + (10 * organism.Cells[index].current) + (1 * @as(usize, @boolToInt(organism.Cells[index].state)));

    return result;
}

test "cell" {
    const cycles = render_cells(1000, 16, 10);
    std.debug.print("{any}  \n", .{cycles - 12297829382473034410});
}
