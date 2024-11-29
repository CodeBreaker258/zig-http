const std = @import("std");
const xev = @import("xev");

pub const CompletionPool = std.heap.MemoryPoolExtra(xev.Completion, .{});
pub const ClientPool = std.heap.MemoryPoolExtra(Client, .{});

//Defined Client and necessary functions to relay info and shut down connection to server
pub const Client = struct {
    id: u32,
    socket: xev.TCP,
    loop: *xev.Loop,
    arena: std.heap.ArenaAllocator,
    client_pool: *ClientPool,
    completion_pool: *CompletionPool,
    read_buf: [4096]u8 = undefined,

    const Self = @This();

    pub fn work(self: *Self) void {
        const c_read = self.completion_pool.create() catch unreachable;
        self.socket.read(self.loop, c_read, .{ .slice = &self.read_buf }, Client, self, Client.readCallback);
    }

    pub fn readCallback(
        self_: ?*Client,
        l: *xev.Loop,
        c: *xev.Completion,
        s: xev.TCP,
        buf: xev.ReadBuffer,
        r: xev.TCP.ReadError!usize,
    ) xev.CallbackAction {
        const self = self_.?;
        const n = r catch |err| {
            std.log.err("read error {any}", .{err});
            s.shutdown(l, c, Client, self, shutdownCallback);
            return .disarm;
        };
        const data = buf.slice[0..n];

        std.log.info("{s}", .{data});

        const httpOk =
            \\HTTP/1.1 200 OK
            \\Content-Type: text/plain
            \\Server: xev-http
            \\Content-Length: {d}
            \\Connection: close
            \\
            \\{s}
        ;

        const content_str =
            \\Hello, World! {d}
        ;

        const content = std.fmt.allocPrint(self.arena.allocator(), content_str, .{self.id}) catch unreachable;
        const res = std.fmt.allocPrint(self.arena.allocator(), httpOk, .{ content.len, content }) catch unreachable;

        self.socket.write(self.loop, c, .{ .slice = res }, Client, self, writeCallback);

        return .disarm;
    }

    fn writeCallback(
        self_: ?*Client,
        l: *xev.Loop,
        c: *xev.Completion,
        s: xev.TCP,
        buf: xev.WriteBuffer,
        r: xev.TCP.WriteError!usize,
    ) xev.CallbackAction {
        _ = buf; // autofix
        _ = r catch unreachable;

        const self = self_.?;
        s.shutdown(l, c, Client, self, shutdownCallback);

        return .disarm;
    }

    fn shutdownCallback(
        self_: ?*Client,
        l: *xev.Loop,
        c: *xev.Completion,
        s: xev.TCP,
        r: xev.TCP.ShutdownError!void,
    ) xev.CallbackAction {
        _ = r catch {};

        const self = self_.?;
        s.close(l, c, Client, self, closeCallback);
        return .disarm;
    }

    fn closeCallback(
        self_: ?*Client,
        l: *xev.Loop,
        c: *xev.Completion,
        socket: xev.TCP,
        r: xev.TCP.CloseError!void,
    ) xev.CallbackAction {
        _ = l;
        _ = r catch unreachable;
        _ = socket;

        var self = self_.?;
        self.arena.deinit();
        self.completion_pool.destroy(c);
        self.client_pool.destroy(self);
        return .disarm;
    }

    pub fn destroy(self: *Self) void {
        self.arena.deinit();
        self.client_pool.destroy(self);
    }
};
