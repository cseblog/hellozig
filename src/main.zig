const std = @import("std");
const fs = std.fs;
const print = std.debug.print;

pub fn main() !void {
    const Data = struct { min: f64 = 0, sum: f64 = 0, max: f64 = 0, count: f64 = 0 };
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    var data_map = std.StringHashMap(Data).init(allocator);
    defer data_map.deinit();

    const filename = "measurements-1000000000.txt";
    const file = try fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    var line = std.ArrayList(u8).init(allocator);
    defer line.deinit();

    var line_no: i32 = 1;
    while (reader.streamUntilDelimiter(line.writer(), '\n', null)) : (line_no += 1) {
        var iter = std.mem.split(u8, line.items, ";");

        var result: [2][]const u8 = undefined;
        var i: u32 = 0;
        while (iter.next()) |x| {
            result[i] = x;
            i = i + 1;
        }

        const city_copy = try allocator.alloc(u8, result[0].len);
        @memcpy(city_copy, result[0]);

        if (data_map.contains(city_copy)) { // do not thing
            const tt = std.fmt.parseFloat(f64, result[1]);
            if (tt) |t| {
                var d = data_map.get(city_copy).?;
                if (d.min > t) {
                    d.min = t;
                }

                if (d.max < t) {
                    d.max = t;
                }

                d.sum = d.sum + t;
                d.count = d.count + 1;
                print("{d} \n", .{line_no});
            } else |_| {
                //Do nothing
            }
        } else {
            const tt = std.fmt.parseFloat(f64, result[1]);
            if (tt) |t| {
                const d = Data{ .min = t, .sum = t, .max = t, .count = 0 };
                try data_map.put(city_copy, d);
                print("{d} \n", .{line_no});
            } else |_| {}
        }

        // Clear the line so we can reuse it.
        defer line.clearRetainingCapacity();
    } else |err| switch (err) {
        error.EndOfStream => {}, // Continue on
        else => return err, // Propagate error
    }
}
