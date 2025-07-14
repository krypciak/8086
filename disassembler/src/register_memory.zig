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
        return self.data[index] + (self.data[index + 1] << 8);
    }

    pub fn get_value(register: u8, wide: bool) u16 {
        if (wide) return get_value_word(register);
        return get_value_byte(register);
    }

    fn set_value_byte(self: *const RegisterMemory, register: u8, value: u8) void {
        self.data[index_byte(register)] = value;
    }

    fn set_value_word(self: *const RegisterMemory, register: u8, value: u16) void {
        const index = index_word(register);
        self.data[index] = value & 0b11111111;
        self.data[index + 1] = value & 0b1111111100000000;
    }

    pub fn set_value(register: u8, value: u16, wide: bool) void {
        if (wide) {
            set_value_word(register, value);
        } else {
            set_value_byte(register, value);
        }
    }
};

test "hi" {
    try std.testing.expect(false);
}
