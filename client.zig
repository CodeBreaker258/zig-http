const std = @import("std");
const http = @import("http.zig");

pub const Client = struct {
    id: u32,
    socket: std.net.Stream,
    read_buf: [4096]u8,

    pub fn init(id: u32, socket: std.net.Stream) Client {
        return Client{
            .id = id,
            .socket = socket,
            .read_buf = undefined,
        };
    }

    /// Handles the client connection
    pub fn handle(self: *Client) !void {
        while (true) {
            const response = try http.parseRequest(self.socket);
            try self.sendResponse(response);
            // For simplicity, close after one response
            try self.close();
            break;
        }
    }

    /// Sends the HTTP response to the client
    fn sendResponse(self: *Client, resp: http.Response) !void {
        var writer = self.socket.writer();
        defer writer.deinit();

        // Write status line
        try writer.print("HTTP/1.1 {d} {s}\r\n", .{ resp.status_code, resp.reason }) catch {};

        // Write headers
        var iter = resp.headers.iterator();
        while (iter.next()) |entry| {
            try writer.print("{s}: {s}\r\n", .{ entry.key, entry.value }) catch {};
        }

        // End of headers
        try writer.print("\r\n", .{}) catch {};

        // Write body
        try writer.writeAll(resp.body) catch {};
    }

    /// Gracefully close the connection
    pub fn close(self: *Client) !void {
        try self.socket.close();
    }
};
