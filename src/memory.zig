const std = @import("std");

pub const RegisterMemory = struct {
    data: [16]u8 = [_]u8{0} ** 16,

    fn index_byte(register: u8) u8 {
        std.debug.assert(register < 8);
        if (register <= 3) return register * 2;
        return (register - 4) * 2 + 1;
    }

    fn index_word(register: u8) u8 {
        std.debug.assert(register < 8);
        return register * 2;
    }

    fn get_value_byte(self: *const RegisterMemory, register: u8) u16 {
        std.debug.assert(register < 8);
        return self.data[index_byte(register)];
    }

    fn get_value_word(self: *const RegisterMemory, register: u8) u16 {
        const index = index_word(register);
        return self.data[index] + (@as(u16, self.data[index + 1]) << 8);
    }

    pub fn get_value(register: u8, wide: bool) u16 {
        if (wide) return get_value_word(register);
        return get_value_byte(register);
    }

    fn set_value_byte(self: *RegisterMemory, register: u8, value: u8) void {
        self.data[index_byte(register)] = value;
    }

    fn set_value_word(self: *RegisterMemory, register: u8, value: u16) void {
        const index = index_word(register);
        self.data[index] = @as(u8, @truncate(value));
        self.data[index + 1] = @as(u8, @truncate(value >> 8));
    }

    pub fn set_value(register: u8, value: u16, wide: bool) void {
        if (wide) {
            set_value_word(register, value);
        } else {
            set_value_byte(register, value);
        }
    }
};

test "register memory" {
    var mem = RegisterMemory{};
    try std.testing.expectEqual(0, mem.get_value_byte(0));
    try std.testing.expectEqual(0, mem.get_value_word(0));

    mem.set_value_byte(3, 26);
    try std.testing.expectEqual(26, mem.get_value_byte(3));
    try std.testing.expectEqual(26, mem.get_value_word(3));

    mem.set_value_word(1, 513);
    try std.testing.expectEqual(513, mem.get_value_word(1));
    try std.testing.expectEqual(1, mem.get_value_byte(1));
    try std.testing.expectEqual(2, mem.get_value_byte(1 + 4));
}

pub const RandomAccessMemory = struct {
    data: [1024 * 1024]u8 = [_]u8{0} ** (1024 * 1024),

    fn index_byte(address: u16) u16 {
        return address;
    }

    fn index_word(address: u16) u16 {
        return address;
    }

    fn get_value_byte(self: *const RandomAccessMemory, address: u16) u16 {
        return self.data[index_byte(address)];
    }

    fn get_value_word(self: *const RandomAccessMemory, address: u16) u16 {
        const index = index_word(address);
        return self.data[index] + (@as(u16, self.data[index + 1]) << 8);
    }

    pub fn get_value(address: u16, wide: bool) u16 {
        if (wide) return get_value_word(address);
        return get_value_byte(address);
    }

    fn set_value_byte(self: *RandomAccessMemory, address: u16, value: u8) void {
        self.data[index_byte(address)] = value;
    }

    fn set_value_word(self: *RandomAccessMemory, address: u8, value: u16) void {
        const index = index_word(address);
        self.data[index] = @as(u8, @truncate(value));
        self.data[index + 1] = @as(u8, @truncate(value >> 8));
    }

    pub fn set_value(address: u16, value: u16, wide: bool) void {
        if (wide) {
            set_value_word(address, value);
        } else {
            set_value_byte(address, value);
        }
    }
};

test "random access memory" {
    var mem = RandomAccessMemory{};
    try std.testing.expectEqual(0, mem.get_value_byte(0));
    try std.testing.expectEqual(0, mem.get_value_word(0));

    mem.set_value_byte(3, 26);
    try std.testing.expectEqual(26, mem.get_value_byte(3));
    try std.testing.expectEqual(26, mem.get_value_word(3));

    mem.set_value_word(1, 513);
    try std.testing.expectEqual(513, mem.get_value_word(1));
    try std.testing.expectEqual(1, mem.get_value_byte(1));
    try std.testing.expectEqual(2, mem.get_value_byte(2));
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
