const std = @import("std");
const xev = @import("xev");

const Allocator = std.mem.Allocator;

const clients = @import("client.zig");
const Client = clients.Client;
const CompletionPool = clients.CompletionPool;
const ClientPool = clients.ClientPool;

//Defined Server and utilized in main.zig
pub const Server = struct {
    loop: *xev.Loop,
    gpa: Allocator,
    completion_pool: *CompletionPool,
    client_pool: *ClientPool,
    conns: u32 = 0,

    pub fn acceptCallback(
        self_: ?*Server,
        l: *xev.Loop, //keep acceptance loop going regardless of completion
        _: *xev.Completion,
        r: xev.TCP.AcceptError!xev.TCP,
    ) xev.CallbackAction {
        const self = self_.?;
        var client = self.client_pool.create() catch unreachable;
        client.* = Client{
            .id = self.conns,
            .loop = l,
            .socket = r catch unreachable,
            .arena = std.heap.ArenaAllocator.init(self.gpa),
            .client_pool = self.client_pool,
            .completion_pool = self.completion_pool,
        };
        client.work();

        self.conns += 1;

        return .rearm;
    }
};
