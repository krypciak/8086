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

    pub fn getValue(self: *const RegisterMemory, register: u8, wide: bool) u16 {
        return if (wide) self.getValueWord(register) else self.getValueByte(register);
    }

    fn setValueByte(self: *RegisterMemory, register: u8, value: u8) void {
        self.data[indexByte(register)] = value;
    }

    fn setValueWord(self: *RegisterMemory, register: u8, value: u16) void {
        const index = indexWord(register);
        self.data[index] = @as(u8, @truncate(value));
        self.data[index + 1] = @as(u8, @truncate(value >> 8));
    }

    pub fn setValue(self: *RegisterMemory, register: u8, wide: bool, value: u16) void {
        if (wide) {
            self.setValueWord(register, value);
        } else {
            self.setValueByte(register, @truncate(value));
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

    mem.setValueWord(1, 513);
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
    const Flags = enum(u8) {
        Carry = 0,
        Parity = 2,
        Auxiliary = 4,
        Zero = 6,
        Sign = 7,
        Trap = 8,
        Interrupt = 9,
        Direction = 10,
        Overflow = 11,
    };

    flags: [16]bool = [_]bool{false} ** 16,

    fn getFlag(self: *const FlagsMemory, flag: FlagsMemory.Flags) bool {
        return self.flags[@intFromEnum(flag)];
    }

    fn setFlag(self: *FlagsMemory, flag: FlagsMemory.Flags, set: bool) void {
        self.flags[@intFromEnum(flag)] = set;
    }
};

test "flags memory" {
    var flags = FlagsMemory{};

    try std.testing.expectEqual(false, flags.getFlag(.Interrupt));
    flags.setFlag(.Auxiliary, true);
    try std.testing.expectEqual(true, flags.getFlag(.Auxiliary));
}
