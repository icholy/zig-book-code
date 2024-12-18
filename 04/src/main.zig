const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var reader = std.io.getStdIn().reader();
    const input = try reader.readAllAlloc(allocator, 500 << 20);
    const output = try Base64.encode(allocator, input);
    try std.io.getStdOut().writeAll(output);
}

const default_table = base64scale();

fn base64scale() [64]u8 {
    var scale: [64]u8 = undefined;
    for ('A'..('Z' + 1), 0..) |c, i| {
        scale[i] = @intCast(c);
    }
    for ('a'..('z' + 1), 26..) |c, i| {
        scale[i] = @intCast(c);
    }
    for ('0'..('9' + 1), 52..) |c, i| {
        scale[i] = @intCast(c);
    }
    scale[62] = '+';
    scale[63] = '/';
    return scale;
}

const Base64 = struct {
    fn _encode_len(input_len: usize) usize {
        var n_groups = input_len / 3;
        if (input_len % 3 != 0) {
            n_groups += 1;
        }
        return n_groups * 4;
    }

    fn _encode_group(group: [3]u8, n: usize) [4]u8 {
        var output: [4]u8 = .{ 0, 0, 0, 0 };
        output[0] = group[0] >> 2;
        output[1] |= (group[0] & 0x3) << 4;
        if (n > 1) {
            output[1] |= group[1] >> 4;
            output[2] |= (group[1] & 0xF) << 2;
        }
        if (n > 2) {
            output[2] |= group[2] >> 6;
            output[3] |= group[2] & 0x3F;
        }
        return .{
            default_table[output[0]],
            default_table[output[1]],
            if (n > 1) default_table[output[2]] else '=',
            if (n > 2) default_table[output[3]] else '=',
        };
    }

    fn encode(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
        var buffer = try allocator.alloc(u8, _encode_len(input.len));
        var offset: usize = 0;
        var i: usize = 0;
        while (i < input.len) : (i += 3) {
            const group = switch (input.len - i) {
                1 => _encode_group(.{ input[i], 0, 0 }, 1),
                2 => _encode_group(.{ input[i], input[i + 1], 0 }, 2),
                else => _encode_group(.{ input[i], input[i + 1], input[i + 2] }, 3),
            };
            buffer[offset] = group[0];
            buffer[offset + 1] = group[1];
            buffer[offset + 2] = group[2];
            buffer[offset + 3] = group[3];
            offset += 4;
        }
        return buffer;
    }
};

test "base64scale returns the right value" {
    const scale = base64scale();
    try std.testing.expectEqualStrings("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/", &scale);
}

test "_encode_len" {
    try std.testing.expectEqual(0, Base64._encode_len(0));
    try std.testing.expectEqual(4, Base64._encode_len(1));
    try std.testing.expectEqual(8, Base64._encode_len(4));
}

test "_encode_group" {
    const tests = .{
        .{ .group = [3]u8{ 'H', 'i', 0 }, .b64 = "SGk=", .n = 2 },
        .{ .group = [3]u8{ 'a', 'a', 'a' }, .b64 = "YWFh", .n = 3 },
        .{ .group = [3]u8{ 's', 'd', 'f' }, .b64 = "c2Rm", .n = 3 },
        .{ .group = [3]u8{ 'a', 0, 0 }, .b64 = "YQ==", .n = 1 },
        .{ .group = [3]u8{ 's', 't', 0 }, .b64 = "c3Q=", .n = 2 },
    };
    inline for (tests) |t| {
        try std.testing.expectEqualStrings(t.b64, &Base64._encode_group(t.group, t.n));
    }
}

test "encode" {
    const tests = .{
        .{ .input = "a", .output = "YQ==" },
        .{ .input = "Test", .output = "VGVzdA==" },
        .{ .input = "st", .output = "c3Q=" },
    };

    inline for (tests) |t| {
        const encoded = try Base64.encode(std.testing.allocator, t.input);
        defer std.testing.allocator.free(encoded);
        try std.testing.expectEqualStrings(t.output, encoded);
    }
}

// run: 'zig build test --fuzz' to run
test "fuzz" {
    const global = struct {
        fn testOne(input: []const u8) anyerror!void {
            // encode using stdlib
            const enc = std.base64.Base64Encoder.init(std.base64.standard_alphabet_chars, '=');
            const buffer = try std.testing.allocator.alloc(u8, enc.calcSize(input.len));
            defer std.testing.allocator.free(buffer);
            const b = enc.encode(buffer, input);

            // encode using ours
            const a = try Base64.encode(std.testing.allocator, input);
            defer std.testing.allocator.free(a);

            // make sure they're the same
            try std.testing.expectEqualStrings(a, b);
        }
    };
    try std.testing.fuzz(global.testOne, .{});
}
