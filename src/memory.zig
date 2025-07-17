const std = @import("std");

pub const RegisterMemory = struct {
    pub const RegisterByte = enum {
        AL,
        CL,
        DL,
        BL,
        AH,
        CH,
        DH,
        BH,
    };
    pub const RegisterWord = enum { AX, CX, DX, BX, SP, BP, SI, DI, ES, CS, SS, DS };

    main: [8]u8 = [_]u8{0} ** 8,
    rest: [8]u16 = [_]u16{0} ** 8,
    ip: u16 = 0,

    // these funcions are for setting registers AX - SP,
    // ES CS SS DS are accessed and set manualy

    fn indexByte(register: RegisterByte) u8 {
        const val = @intFromEnum(register);
        std.debug.assert(val < 8);
        if (val <= 3) return val * 2;
        return (val - 4) * 2 + 1;
    }

    fn indexWord(register: RegisterWord) u8 {
        const val = @intFromEnum(register);
        std.debug.assert(val < 8);
        return val * 2;
    }

    fn getValueByte(self: *const RegisterMemory, register: RegisterByte) u16 {
        return self.main[indexByte(register)];
    }

    fn getValueWord(self: *const RegisterMemory, register: RegisterWord) u16 {
        if (@intFromEnum(register) >= 4) {
            return self.rest[@intFromEnum(register) - 4];
        } else {
            const index = indexWord(register);
            return self.main[index] + (@as(u16, self.main[index + 1]) << 8);
        }
    }

    pub fn getValue(self: *const RegisterMemory, register: u8, wide: bool) u16 {
        return if (wide) {
            return self.getValueWord(@enumFromInt(register));
        } else {
            return self.getValueByte(@enumFromInt(register));
        };
    }

    fn setValueByte(self: *RegisterMemory, register: RegisterByte, value: u8) void {
        self.main[indexByte(register)] = value;
    }

    fn setValueWord(self: *RegisterMemory, register: RegisterWord, value: u16) void {
        if (@intFromEnum(register) >= 4) {
            self.rest[@intFromEnum(register) - 4] = value;
        } else {
            const index = indexWord(register);
            self.main[index] = @as(u8, @truncate(value));
            self.main[index + 1] = @as(u8, @truncate(value >> 8));
        }
    }

    pub fn setValue(self: *RegisterMemory, register: u8, wide: bool, value: u16) void {
        if (wide) {
            self.setValueWord(@enumFromInt(register), value);
        } else {
            std.debug.assert(value <= std.math.maxInt(u8));
            self.setValueByte(@enumFromInt(register), @truncate(value));
        }
    }
};

test "register memory" {
    var mem = RegisterMemory{};
    try std.testing.expectEqual(0, mem.getValueByte(.AL));
    try std.testing.expectEqual(0, mem.getValueWord(.AX));

    mem.setValueByte(.BL, 26);
    try std.testing.expectEqual(26, mem.getValueByte(.BL));
    try std.testing.expectEqual(26, mem.getValueWord(.BX));

    mem.setValueWord(.CX, 513);
    try std.testing.expectEqual(513, mem.getValueWord(.CX));
    try std.testing.expectEqual(1, mem.getValueByte(.CL));
    try std.testing.expectEqual(2, mem.getValueByte(.CH));
}

pub const RandomAccessMemory = struct {
    data: [1024 * 1024]u8 = [_]u8{0} ** (1024 * 1024),

    fn indexByte(address: u16) u16 {
        return address;
    }

    fn indexWord(address: u16) u16 {
        return address;
    }

    fn getValueByte(self: *const RandomAccessMemory, address: u16) u16 {
        return self.data[indexByte(address)];
    }

    fn getValueWord(self: *const RandomAccessMemory, address: u16) u16 {
        const index = indexWord(address);
        return self.data[index] + (@as(u16, self.data[index + 1]) << 8);
    }

    pub fn getValue(self: *const RandomAccessMemory, address: u16, wide: bool) u16 {
        return if (wide) self.getValueWord(address) else self.getValueByte(address);
    }

    fn setValueByte(self: *RandomAccessMemory, address: u16, value: u8) void {
        self.data[indexByte(address)] = value;
    }

    fn setValueWord(self: *RandomAccessMemory, address: u16, value: u16) void {
        const index = indexWord(address);
        self.data[index] = @as(u8, @truncate(value));
        self.data[index + 1] = @as(u8, @truncate(value >> 8));
    }

    pub fn setValue(self: *RandomAccessMemory, address: u16, wide: bool, value: u16) void {
        if (wide) {
            self.setValueWord(address, value);
        } else {
            self.setValueByte(address, @truncate(value));
        }
    }
};

test "random access memory" {
    var mem = RandomAccessMemory{};
    try std.testing.expectEqual(0, mem.getValueByte(0));
    try std.testing.expectEqual(0, mem.getValueWord(0));

    mem.setValueByte(3, 26);
    try std.testing.expectEqual(26, mem.getValueByte(3));
    try std.testing.expectEqual(26, mem.getValueWord(3));

    mem.setValueWord(1, 513);
    try std.testing.expectEqual(513, mem.getValueWord(1));
    try std.testing.expectEqual(1, mem.getValueByte(1));
    try std.testing.expectEqual(2, mem.getValueByte(2));
}

pub const FlagsMemory = struct {
    carry: bool = false,
    parity: bool = false,
    auxiliary: bool = false,
    zero: bool = false,
    sign: bool = false,
    trap: bool = false,
    interrupt: bool = false,
    direction: bool = false,
    overflow: bool = false,
};
