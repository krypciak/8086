const std = @import("std");

pub const RegisterMemory = struct {
    data: [16]u8 = [_]u8{0} ** 16,

    fn indexByte(register: u8) u8 {
        std.debug.assert(register < 8);
        if (register <= 3) return register * 2;
        return (register - 4) * 2 + 1;
    }

    fn indexWord(register: u8) u8 {
        std.debug.assert(register < 8);
        return register * 2;
    }

    fn getValueByte(self: *const RegisterMemory, register: u8) u16 {
        std.debug.assert(register < 8);
        return self.data[indexByte(register)];
    }

    fn getValueWord(self: *const RegisterMemory, register: u8) u16 {
        const index = indexWord(register);
        return self.data[index] + (@as(u16, self.data[index + 1]) << 8);
    }

    pub fn getValue(register: u8, wide: bool) u16 {
        if (wide) return getValueWord(register);
        return getValueByte(register);
    }

    fn setValueByte(self: *RegisterMemory, register: u8, value: u8) void {
        self.data[indexByte(register)] = value;
    }

    fn setValue_word(self: *RegisterMemory, register: u8, value: u16) void {
        const index = indexWord(register);
        self.data[index] = @as(u8, @truncate(value));
        self.data[index + 1] = @as(u8, @truncate(value >> 8));
    }

    pub fn setValue(register: u8, value: u16, wide: bool) void {
        if (wide) {
            setValue_word(register, value);
        } else {
            setValueByte(register, value);
        }
    }
};

test "register memory" {
    var mem = RegisterMemory{};
    try std.testing.expectEqual(0, mem.getValueByte(0));
    try std.testing.expectEqual(0, mem.getValueWord(0));

    mem.setValueByte(3, 26);
    try std.testing.expectEqual(26, mem.getValueByte(3));
    try std.testing.expectEqual(26, mem.getValueWord(3));

    mem.setValue_word(1, 513);
    try std.testing.expectEqual(513, mem.getValueWord(1));
    try std.testing.expectEqual(1, mem.getValueByte(1));
    try std.testing.expectEqual(2, mem.getValueByte(1 + 4));
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

    pub fn getValue(address: u16, wide: bool) u16 {
        if (wide) return getValueWord(address);
        return getValueByte(address);
    }

    fn setValueByte(self: *RandomAccessMemory, address: u16, value: u8) void {
        self.data[indexByte(address)] = value;
    }

    fn setValue_word(self: *RandomAccessMemory, address: u8, value: u16) void {
        const index = indexWord(address);
        self.data[index] = @as(u8, @truncate(value));
        self.data[index + 1] = @as(u8, @truncate(value >> 8));
    }

    pub fn setValue(address: u16, value: u16, wide: bool) void {
        if (wide) {
            setValue_word(address, value);
        } else {
            setValueByte(address, value);
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

    mem.setValue_word(1, 513);
    try std.testing.expectEqual(513, mem.getValueWord(1));
    try std.testing.expectEqual(1, mem.getValueByte(1));
    try std.testing.expectEqual(2, mem.getValueByte(2));
}

pub const FlagsMemory = struct {
    const Flags = enum {
        Carry,
        Parity,
        Auxiliary,
        Zero,
        Sign,
        Trap,
        Interrupt,
        Direction,
        Overflow,
    };
};
