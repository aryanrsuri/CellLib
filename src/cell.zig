//!                 Cell.zig
//!     DATE CREATED    July 4, 2023
//!     LICENSE        GNU
//!     COPYRIGHT (C) 2023 aryanrsuri
//!
//!     Cell.zig implements Cell struct which is a unit of binary action (1 or 0)
//!     Cell.zig implements Structure struct which contains array of Cell structure
//!     of size N and implements simulation of these Cell growth
//!

pub const std = @import("std");
var shuffle = std.rand.DefaultPrng.init(0);

/// Cell represents a unit of binary action (1/0) with a
/// current "health" where once greater than
/// a specified mark will grow to a next "cycle"
/// @params {bool} state
/// @params {usize} current
/// @params {usize} cycles
pub const Cell = struct {
    const Self = @This();
    var threshold: usize = 16;
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
        _ = self;
    }

    pub fn grow(self: *Self, amount: usize) void {
        self.current += amount;
        self.state = true;
        if (self.current > threshold) {
            self.state = true;
            self.cycles += 1;
            threshold += 1;
            self.current = 0;
        }
    }
};

const Context = enum(u8) {
    state,
    cycles,
    verbose,
};

/// Structure represents a array of Cells that
/// can grow, interact with neighbouring cells
pub const Structure = struct {
    const Self = @This();
    Cells: []Cell,
    Allocator: std.mem.Allocator,

    /// Initialise structure struct
    /// @params {mem alloc} allocator
    /// @params {usize} number of cells
    /// @returns Structure {.cells .alloc}
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

    /// Randomly set alive cells to dead and dead cells alive
    /// This should only be run at the start to implement a
    /// "self contained" --> cells are inverted based only on other cells
    /// vs a
    /// "open" --> cells are shufflled after each generation to simulate environment
    /// structure
    /// @params {self} *Structure
    /// @returns {Error Void}
    pub fn shuffle_cells(self: *Self) !void {
        var iterator: usize = 0;
        const size = self.Cells.len;
        while (iterator < size) : (iterator = iterator + 1) {
            var index = shuffle.random().intRangeAtMost(usize, 0, size - 1);
            _ = try self.invert_cell(index);
        }
    }

    // fn grow_cell(self: *Self, index: usize) !void {
    //     if (index > self.Cells.len) return error.SaturedStructure;
    //     self.Cells[index].grow(index);
    // }
    //
    pub fn get_cell(self: *Self, index: usize) !*Cell {
        if (index > self.Cells.len) return error.SaturedStructure;
        var safe_cell: Cell = self.Cells[index];
        return &safe_cell;
    }

    pub fn get_cells(self: *Self) []Cell {
        return self.Cells;
    }

    /// Cycle structure
    /// @param {self} Structure*
    /// @returns {Error Void}
    pub fn cycle(self: *Self) !void {
        var iter: usize = 1;
        while (iter < self.Cells.len - 1) : (iter += 1) {
            var curr = &self.Cells[iter];
            var prev = &self.Cells[iter - 1];
            var peek = &self.Cells[iter + 1];
            if (prev.state or peek.state) {
                prev.invert();
                peek.invert();
                _ = curr.grow(self.Cells.len);
            }
        }
        // _ = try self.shuffle_cells();
    }

    /// Simulate structure for > 1 generation
    /// @param {self} Structure *
    /// @param {usize} gens n . gnenerations
    /// @returns {Error Void}
    pub fn simulate(self: *Self, generations: usize) !void {
        var gen: usize = 0;
        while (gen <= generations) : (gen += 1) {
            _ = try self.cycle();
        }
    }

    pub fn print(self: *Self, context: Context) void {
        std.debug.print("\n\n -{}- ", .{context});
        for (self.Cells, 0..) |cell, i| {
            if (i % 4 == 0) {
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

pub const Structure2D = struct {
    const Self = @This();
    n: usize,
    Cells: [][]Cell,
    Allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, comptime stride: usize) Structure2D {
        // var rows = allocator.alloc(Cell, stride);
        // var cells = allocator.alloc(rows, stride);
        var cells: [stride][stride]Cell = undefined;

        return .{ .Cells = cells, .Allocator = allocator };
    }

    pub fn deinit(self: *Self) void {
        // for (self.Cells.*) |rows| {
        // self.Allocator.free(rows);
        // }
        self.Allocator.free(self.Cells);
        self.* = undefined;
    }
};
test "test " {
    var t = Structure.init(std.testing.allocator, 16);
    var two = Structure2D.init(std.testing.allocator, 4);
    defer {
        t.deinit();
        two.deinit();
    }
    _ = try t.shuffle_cells();
    _ = try t.simulate(3000);
    t.print(Context.cycles);

    std.debug.print("twoo {any}", .{two});
}
