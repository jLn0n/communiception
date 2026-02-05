local types = require("@self/types")

local EventServer = require("@self/event/server")
local RPCServer = require("@self/rpc/server")

export type Event<A...> = EventServer.EventServer<A...>
export type RPC<A..., R...> = RPCServer.RPCServer<A..., R...>

local communiception = {}

function communiception.event<A...>(channel: types.CommunicationChannelType, id: string): Event<A...>
	return EventServer(channel, id) :: any
end

function communiception.rpc<A..., R...>(id: string): RPC<A..., R...>
	return RPCServer(id) :: any
end

return communiception