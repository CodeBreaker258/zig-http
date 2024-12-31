const std = @import("std");

// formerly httpServer.zig file in previous commit
const clients = @import("client.zig");
const Client = clients.Client;
const CompletionPool = clients.CompletionPool;
const ClientPool = clients.ClientPool;

const Server = @import("server.zig").Server;

const net = std.net;
const Allocator = std.mem.Allocator;

pub fn main() !void {
    const gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    // Fix for Zig 0.13.0: Remove '.allocator' and use '&gpa' directly
    const alloc = &gpa;

    const port = 8080;
    const addr = try net.Address.parseIp4("0.0.0.0", port);

    std.log.info("Listening on port {}", .{port});

    // Create the TCP socket
    const listener = try net.StreamServer.initTcp4(alloc, addr);
    defer listener.deinit();

    var completion_pool = CompletionPool.init(alloc);
    defer completion_pool.deinit();

    var client_pool = ClientPool.init(alloc);
    defer client_pool.deinit();

    var server = Server{
        .gpa = alloc,
        .completion_pool = &completion_pool,
        .client_pool = &client_pool,
    };

    while (true) {
        const conn = try listener.accept();
        async handleConnection(&server, conn) catch |err| {
            std.log.err("Failed to handle connection: {}", .{err});
        };
    }
}

pub fn handleConnection(server: *Server, conn: std.net.Stream) !void {
    try server.acceptConnection(conn);
}
