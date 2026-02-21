local types = require("@self/types")

local EventClient = require("@self/event/client")
local RPCClient = require("@self/rpc/client")

export type Event<A...> = EventClient.EventClient<A...>
export type RPC<A..., R...> = RPCClient.RPCClient<A..., R...>

local communiception = {}

function communiception.event<A...>(channel: types.CommunicationChannelType, id: string): Event<A...>
	return EventClient(channel, id) :: any
end

function communiception.rpc<A..., R...>(id: string): RPC<A..., R...>
	return RPCClient(id) :: any
end

return communiception
