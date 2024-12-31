const std = @import("std");

pub const Request = struct {
    method: []const u8,
    path: []const u8,
    headers: std.StringHashMap([]const u8),
    body: []const u8,
};

pub const Response = struct {
    status_code: u16,
    reason: []const u8,
    headers: std.StringHashMap([]const u8),
    body: []const u8,
};

pub fn handleRequest(req: Request) Response {
    var response = Response{
        .status_code = 200,
        .reason = "OK",
        .headers = std.StringHashMap([]const u8).init(std.heap.page_allocator),
        .body = "Hello, World!",
    };

    if (std.mem.eql(u8, req.path, "/")) {
        response.body = "Welcome to the Home Page!";
    } else if (std.mem.eql(u8, req.path, "/about")) {
        response.body = "About Page";
    } else {
        response.status_code = 404;
        response.reason = "Not Found";
        response.body = "404 Page Not Found";
    }

    try response.headers.put("Content-Length", std.fmt.allocPrint(std.heap.page_allocator, "{}", .{response.body.len}) catch "");
    try response.headers.put("Content-Type", "text/plain");

    return response;
}

pub fn parseRequest(stream: std.net.Stream) !Response {
    var buffer: [4096]u8 = undefined;
    const bytes_read = try stream.read(&buffer) catch {
        return error.ConnectionClosed;
    };
    if (bytes_read == 0) return error.ConnectionClosed;

    const data = buffer[0..bytes_read];
    var lines = std.mem.tokenize(data, "\r\n");

    var req = Request{
        .method = "",
        .path = "",
        .headers = std.StringHashMap([]const u8).init(std.heap.page_allocator),
        .body = "",
    };

    var is_headers = true;

    while (lines.next()) |line| {
        if (line.len == 0) {
            is_headers = false;
            continue;
        }

        if (is_headers) {
            if (req.method.len == 0) {
                // Parse request line: METHOD PATH PROTOCOL
                var parts = std.mem.tokenize(line, " ");
                req.method = try parts.next() catch "";
                req.path = try parts.next() catch "";
                // Ignoring protocol for simplicity
            } else {
                // Parse header: Key: Value
                var parts = std.mem.tokenize(line, ": ");
                const key = try parts.next() catch "";
                const value = try parts.next() catch "";
                _ = req.headers.put(key, value) catch {};
            }
        } else {
            // Body
            req.body = line;
        }
    }

    defer req.headers.deinit();

    return handleRequest(req);
}
