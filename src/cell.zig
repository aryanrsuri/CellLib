//!                 Cell.zig
//!     author: aryanrsuri
//!     date created: July 4
//!     LICENCE: ../LICENSE (GNU)
//!
//!     Cell.zig implements Cell struct which is a unit of binary action (1 or 0)
//!     Cell.zig implements Structure struct which contains array of Cell structure
//!     of size N and implements simulation of these Cell growth

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
    var __threshold__: usize = 128;
    state: bool = false,
    current: usize = 0,
    cycles: usize = 0,

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
        self.state = true;
        if (self.current > __threshold__) {
            self.state = true;
            self.cycles += 1;
            __threshold__ += 1;
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

    /// Cycle structure
    /// @param {self} Structure*
    /// @returns {Error Void}
    pub fn cycle(self: *Self) !void {
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

test "test " {
    var t = Structure.init(std.testing.allocator, 128);
    defer t.deinit();

    _ = try t.simulate(100);
    std.debug.print("t : {any}\n", .{t.Cells});
}
