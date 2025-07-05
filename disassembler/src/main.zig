const std = @import("std");
const stdout = std.io.getStdOut();
const allocator = std.heap.page_allocator;

pub fn main() !void {
    const file = try std.fs.cwd().openFile("./asm/mov.e", .{ .mode = .read_only });
    defer file.close();

    var buffer: [100]u8 = undefined;
    const bytes_read = try file.readAll(&buffer);
    const buffer_slice = buffer[0..bytes_read];

    try disassemble(buffer_slice);
}

fn disassemble(data: []const u8) !void {
    try stdout.writeAll("bits 16\n");
    _ = try nextInstruction(data, 0);
}

const Reg = struct {
    val: u8,

    fn getName(self: *const Reg, w: bool) []const u8 {
        const table_w0 = [8][]const u8{ "al", "cl", "dl", "bl", "ah", "ch", "dh", "bh" };
        const table_w1 = [8][]const u8{ "ax", "cx", "dx", "bx", "sp", "bp", "si", "di" };

        if (w) {
            return table_w1[self.val];
        } else {
            return table_w0[self.val];
        }
    }
};

fn nextInstruction(data: []const u8, at: usize) !usize {
    std.debug.print("{b} {b}\n", .{ data[0], data[1] });

    const b1 = data[at];
    const b2 = data[at + 1];
    // const b3 = at + 2;
    // const b4 = at + 3;

    const opcode: u8 = b1 & 0b11111100;
    const d: bool = (b1 & 0b00000010) == 0b00000010;
    const w: bool = (b1 & 0b00000001) == 0b00000001;

    const m1: bool = (b2 & 0b10000000) == 0b10000000;
    const m2: bool = (b2 & 0b01000000) == 0b01000000;

    const reg = Reg{ .val = (b2 & 0b00111000) >> 3 };
    const rm = Reg{ .val = b2 & 0b00000111 };

    std.debug.print("opcode: {}, d: {}, w: {}, m1: {}, m2: {}, reg: {}, rm: {}\n", .{ opcode, d, w, m1, m2, reg, rm });
    switch (opcode) {
        0b10001000 => { // mov
            std.debug.assert(m1);
            std.debug.assert(m2);

            const line = try std.fmt.allocPrint(allocator, "mov {s}, {s}\n", .{ rm.getName(w), reg.getName(w) });
            defer allocator.free(line);

            try stdout.writeAll(line);
            return at;
        },
        else => unreachable,
    }
}
