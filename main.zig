const std = @import("std");
const xev = @import("xev");

//formely httpServer.zig file in previous commit
const clients = @import("client.zig");
const Client = clients.Client;
const CompletionPool = clients.CompletionPool;
const ClientPool = clients.ClientPool;

const Server = @import("server.zig").Server;

const net = std.net;
const Allocator = std.mem.Allocator;

pub fn main() !void {
    var thread_pool = xev.ThreadPool.init(.{});
    defer thread_pool.deinit();
    defer thread_pool.shutdown();

    var loop = try xev.Loop.init(.{
        .entries = 4096,
        .thread_pool = &thread_pool,
    });
    defer loop.deinit();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const port = 3000;
    const addr = try net.Address.parseIp4("0.0.0.0", port);
    var socket = try xev.TCP.init(addr);

    std.log.info("Listening on port {}", .{port});

    try socket.bind(addr);
    try socket.listen(std.os.linux.SOMAXCONN);

    var completion_pool = CompletionPool.init(alloc);
    defer completion_pool.deinit();

    var client_pool = ClientPool.init(alloc);
    defer client_pool.deinit();

    const c = try completion_pool.create();
    var server = Server{
        .loop = &loop,
        .gpa = alloc,
        .completion_pool = &completion_pool,
        .client_pool = &client_pool,
    };

    socket.accept(&loop, c, Server, &server, Server.acceptCallback);
    try loop.run(.until_done);
}
