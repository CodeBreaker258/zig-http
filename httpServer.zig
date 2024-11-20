const std = @import("std");
const http = std.http;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const uri = std.Uri.parse("https://whatthecommit.com") catch unreachable;

    // Header Creation
    var headers = std.http.Headers{ .allocator = allocator };
    defer headers.deinit();

    try headers.append("accept", "*/*");

    var client = std.http.Client.init(allocator);
    defer client.deinit();

    var request = try client.request(.GET, uri, headers, .{});
    defer request.deinit();

    // Handle the response here
    try request.start();

    // Wait for the server to send use a response.
    try request.wait();

    // Read the entire response body, but only allow it to allocate 8KB of memory.
    const body = request.reader().readAllAlloc(allocator, 8192) catch unreachable;
    defer allocator.free(body);

    // Print out the response.
    std.log.info("{s}", .{body});
}
