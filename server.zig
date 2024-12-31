const std = @import("std");
const Allocator = std.mem.Allocator;

const clients = @import("client.zig");
const Client = clients.Client;
const CompletionPool = clients.CompletionPool;
const ClientPool = clients.ClientPool;

pub const Server = struct {
    gpa: *Allocator,
    completion_pool: *CompletionPool,
    client_pool: *ClientPool,
    conns: u32 = 0,

    pub fn acceptConnection(self: *Server, socket: std.net.Stream) !void {
        var client = self.client_pool.create() catch {
            std.log.err("Failed to create client from pool");
            return;
        };
        client.* = Client.init(self.conns, socket);
        self.conns += 1;
        async client.handle() catch |err| {
            std.log.err("Client handle error: {}", .{err});
            try client.close();
        };
    }
};
