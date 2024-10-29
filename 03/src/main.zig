const std = @import("std");
const stdout = std.io.getStdOut().writer();

pub fn main() !void {}

fn input_length(input: []const u8) usize {
    return input.len;
}

test "known at compile time" {
    const name = "Ilia";
    const array = [_]u8{ 1, 2, 3, 4 };
    _ = name;
    _ = array;
}

test "gpa" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const name = "Ilia";
    const output = try std.fmt.allocPrint(allocator, "Hello {s}!!!", .{name});
    try stdout.print("{s}\n", .{output});
}

test "allocate int" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const ptr = try allocator.create(i64);
    defer allocator.destroy(ptr);
    ptr.* = 123;
    try stdout.print("{d}\n", .{ptr.*});
}

test "fixed buffer allocator" {
    var buffer: [100]u8 = undefined;
    for (0..buffer.len) |i| {
        buffer[i] = 0;
    }
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    for (0..10) |i| {
        const x = try allocator.create(f64);
        x.* = @floatFromInt(i);
    }
}
