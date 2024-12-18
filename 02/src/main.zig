const std = @import("std");
const stdout = std.io.getStdOut().writer();

pub fn main() !void {}

test "if statements" {
    const x = 5;
    if (x > 10) {
        std.debug.print("x is > 10\n", .{});
    } else {
        std.debug.print("x is <= 10\n", .{});
    }
}

test "switch statements" {
    const Role = enum { SE, DPE, DE, DA, PM, PO, KS, NONE };
    var area: []const u8 = undefined;
    const role = Role.SE;
    switch (role) {
        .PM, .SE, .DPE, .PO => {
            area = "Platform";
        },
        .DE, .DA => {
            area = "Data & Analytics";
        },
        .KS => {
            area = "Sales";
        },
        else => {
            @panic("unsupported role");
        },
    }
    std.debug.print("{s}\n", .{area});
}

test "switch expression" {
    const level = 100;
    const x = switch (level) {
        1 => "one",
        2 => "two",
        3...100 => "3 - 100",
        else => @panic("invalid"),
    };
    std.debug.print("{s}\n", .{x});
}

test "defer" {
    defer std.debug.print("Existing test ...\n", .{});
    {
        defer std.debug.print("Inside block ... \n", .{});
    }
    std.debug.print("New test ...\n", .{});
}

fn foo() !void {
    return error.FooError;
}

test "errdefer" {
    var i: usize = 1;
    errdefer std.debug.print("Value of i: {d}\n", .{i});
    defer i = 2;
    // try foo();
}

test "for loop" {
    const name = "Pedro";
    for (name, 0..) |char, i| {
        std.debug.print("{d}: {c}\n", .{ i, char });
    }
}

test "while loop" {
    var i: u8 = 1;
    while (i < 3) {
        i += 1;
    }
}

test "while inline increment" {
    var i: u8 = 1;
    while (i < 5) : (i += 2) {
        std.debug.print("{d}\n", .{i});
    }
}

fn add2(x: *u32) void {
    x.* += 2;
}

test "cannot mutate argument" {
    var x: u32 = 2;
    add2(&x);
    std.debug.print("{d}\n", .{x});
}

const User = struct {
    id: u64,
    name: []const u8,
    email: []const u8,

    pub fn init(id: u64, name: []const u8, email: []const u8) User {
        return User{ .id = id, .name = name, .email = email };
    }

    pub fn print_name(self: User) !void {
        try stdout.print("{s}\n", .{self.name});
    }
};

test "struct" {
    const u = User.init(123, "Ilia Choly", "ilia.choly@gmail.com");
    try u.print_name();
}

test "anonymous struct" {
    const s = .{ .id = 1, .name = "Ilia" };
    try stdout.print("{}\n", .{@TypeOf(s)});
}

const Vec3 = struct {
    x: f64,
    y: f64,
    z: f64,

    pub fn distance(self: Vec3, other: Vec3) f64 {
        const dx = self.x - other.x;
        const dy = self.y - other.y;
        const dz = self.z - other.z;
        return @sqrt(dx * dx + dy * dy + dz * dz);
    }

    pub fn double(self: *Vec3) void {
        self.x *= 2;
        self.y *= 2;
        self.z *= 2;
    }
};

test "Vec3 struct" {
    var v = Vec3{ .x = 1, .y = 2, .z = 3 };
    v.double();
    try stdout.print("{d}\n", .{v.distance(v)});
}

test "@as" {
    const x: usize = 5;
    const y = @as(u32, x);
    try std.testing.expect(@TypeOf(y) == u32);
}

test "@castPtr" {
    const bytes align(@alignOf(u32)) = [_]u8{ 12, 12, 12, 12 };
    const u32_ptr: *const u32 = @ptrCast(&bytes);
    try std.testing.expect(@TypeOf(u32_ptr) == *const u32);
}

test "@import" {
    const f = @import("foo.zig");
    try f.hello();
}
