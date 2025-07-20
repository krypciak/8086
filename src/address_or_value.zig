const std = @import("std");

const simulator = @import("simulator.zig");
const SimulatorState = simulator.SimulatorState;

const memory = @import("memory.zig");
const RegisterMemory = memory.RegisterMemory;

pub const Value = struct {
    pub const ShowValueType = enum {
        No,
        Byte,
        Word,
    };

    value: u16,

    pub fn toString(self: *const Value, allocator: std.mem.Allocator, show_value_type: ShowValueType) ![]const u8 {
        if (show_value_type == .No) {
            return std.fmt.allocPrint(allocator, "{d}", .{self.value});
        } else {
            return std.fmt.allocPrint(allocator, "{s} {d}", .{ if (show_value_type == .Word) "word" else "byte", self.value });
        }
    }
};

pub const RegisterAddress = struct {
    register: u8,
    wide: bool,

    fn getMovRegName(val: u8, w: bool) []const u8 {
        if (w) {
            return @as(RegisterMemory.RegisterWord, @enumFromInt(val)).toString();
        } else {
            return @as(RegisterMemory.RegisterByte, @enumFromInt(val)).toString();
        }
    }

    pub fn toString(self: *const RegisterAddress, allocator: std.mem.Allocator) ![]const u8 {
        return std.fmt.allocPrint(allocator, "{s}", .{getMovRegName(self.register, self.wide)});
    }

    pub fn getValue(self: *const RegisterAddress, state: *const SimulatorState) u16 {
        return state.registers.getValue(self.register, self.wide);
    }

    pub fn setValue(self: *const RegisterAddress, state: *SimulatorState, value: u16) void {
        state.registers.setValue(self.register, self.wide, value);
    }
};

pub const MemoryAddress = struct {
    displacement: i16 = 0,
    reg1: ?RegisterMemory.RegisterWord = null,
    reg2: ?RegisterMemory.RegisterWord = null,
    wide: bool,

    pub fn toString(self: *const MemoryAddress, allocator: std.mem.Allocator) ![]const u8 {
        if (self.reg1) |reg1| {
            const sign: u8 = if (self.displacement >= 0) '+' else '-';

            const r1 = reg1.toString();
            if (self.reg2) |reg2| {
                const r2 = reg2.toString();
                if (self.displacement == 0) {
                    return try std.fmt.allocPrint(allocator, "[{s} + {s}]", .{ r1, r2 });
                } else {
                    return try std.fmt.allocPrint(allocator, "[{s} + {s} {c} {d}]", .{ r1, r2, sign, @abs(self.displacement) });
                }
            } else {
                if (self.displacement == 0) {
                    return try std.fmt.allocPrint(allocator, "[{s}]", .{r1});
                } else {
                    return try std.fmt.allocPrint(allocator, "[{s} {c} {d}]", .{ r1, sign, @abs(self.displacement) });
                }
            }
        } else {
            return std.fmt.allocPrint(allocator, "[{d}]", .{self.displacement});
        }
    }

    fn calculateAddress(self: *const MemoryAddress, state: *const SimulatorState) u16 {
        var address: i16 = self.displacement;
        if (self.reg1) |reg1| {
            address += @intCast(state.registers.getValueWord(reg1));

            if (self.reg2) |reg2| {
                address += @intCast(state.registers.getValueWord(reg2));
            }
        }
        std.debug.assert(address >= 0);
        return @intCast(address);
    }

    pub fn getValue(self: *const MemoryAddress, state: *const SimulatorState) u16 {
        const address = self.calculateAddress(state);
        return state.ram.getValue(address, self.wide);
    }

    pub fn setValue(self: *const MemoryAddress, state: *SimulatorState, value: u16) void {
        const address = self.calculateAddress(state);
        state.ram.setValue(address, self.wide, value);
    }

    pub fn estimateCycles(self: *const MemoryAddress) u8 {
        if (self.reg1) |reg1| {
            if (self.reg2) |reg2| {
                const is_faster_variant = (reg1 == .BP and reg2 == .DI) or (reg1 == .BX and reg2 == .SI);
                if (self.displacement == 0) {
                    if (is_faster_variant) {
                        return 7;
                    } else {
                        return 8;
                    }
                } else {
                    if (is_faster_variant) {
                        return 11;
                    } else {
                        return 12;
                    }
                }
            } else {
                if (self.displacement == 0) {
                    return 5;
                } else {
                    return 9;
                }
            }
        } else {
            return 6;
        }
    }
};

pub const AddressOrValue = union(AddressOrValue.Types) {
    pub const Types = enum {
        Value,
        RegisterAddress,
        MemoryAddress,
    };

    Value: Value,
    RegisterAddress: RegisterAddress,
    MemoryAddress: MemoryAddress,

    pub fn toString(self: *const AddressOrValue, allocator: std.mem.Allocator, show_value_type: Value.ShowValueType) ![]const u8 {
        return switch (self.*) {
            .Value => |*byte| byte.toString(allocator, show_value_type),
            .RegisterAddress => |*reg| reg.toString(allocator),
            .MemoryAddress => |*mem| mem.toString(allocator),
        };
    }

    pub fn getValue(self: *const AddressOrValue, state: *const SimulatorState) u16 {
        return switch (self.*) {
            .Value => |*v| v.value,
            .RegisterAddress => |*reg| reg.getValue(state),
            .MemoryAddress => |*mem| mem.getValue(state),
        };
    }

    pub fn setValue(self: *const AddressOrValue, state: *SimulatorState, value: u16) void {
        switch (self.*) {
            .Value => unreachable,
            .RegisterAddress => |*reg| reg.setValue(state, value),
            .MemoryAddress => |*mem| mem.setValue(state, value),
        }
    }

    pub fn isWide(self: *const AddressOrValue) bool {
        return switch (self.*) {
            .Value => unreachable,
            .RegisterAddress => |*reg| reg.wide,
            .MemoryAddress => |*mem| mem.wide,
        };
    }

    pub fn tag(self: *const AddressOrValue) Types {
        return switch (self.*) {
            .Value => Types.Value,
            .RegisterAddress => Types.RegisterAddress,
            .MemoryAddress => Types.MemoryAddress,
        };
    }
};
