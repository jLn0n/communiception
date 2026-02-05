local types = require("@self/types")

local EventClient = require("@self/event/client")
local RPCClient = require("@self/rpc/client")

export type EventClient<A...> = EventClient.EventClient<A...>
export type RPCClient<A..., R...> = RPCClient.RPCClient<A..., R...>

local communiception = {}

function communiception.event<A...>(
	channel: types.CommunicationChannelType, id: string): EventClient<A...>
	return EventClient(channel, id) :: any
end

function communiception.rpc<A..., R...>(id: string): RPCClient<A..., R...>
	return RPCClient(id) :: any
end

return communiception
