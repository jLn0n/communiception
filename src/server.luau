local types = require("@self/types")

local EventServer = require("@self/event/server")
local RPCServer = require("@self/rpc/server")

export type EventServer<A...> = EventServer.EventServer<A...>
export type RPCServer<A..., R...> = RPCServer.RPCServer<A..., R...>

local communiception = {}

function communiception.event<A...>(channel: types.CommunicationChannelType, id: string): EventServer<A...>
	return EventServer(channel, id) :: any
end

function communiception.rpc<A..., R...>(id: string): RPCServer<A..., R...>
	return RPCServer(id) :: any
end

return communiception