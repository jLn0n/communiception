local pktshareds = require("../pktshareds")
local types = require("../types")

type EventClientCallback<A...> = (A...) -> ()
export type EventClient<A...> = {
	id: string,
	channel: types.CommunicationChannelType,

	send: (self: EventClient<A...>, A...) -> (),
	listen: (self: EventClient<A...>, EventClientCallback<A...>) -> (() -> ()),
	listenOnce: (self: EventClient<A...>, EventClientCallback<A...>) -> (() -> ()),
	wait: (self: EventClient<A...>) -> (A...),
	dispose: (self: EventClient<A...>) -> (),
}

type EventClientInternal = {
	id: string,
	channel: types.CommunicationChannelType,

	_internal: {
		listener_count: number,
		listeners: {EventClientCallback<...any>},
	},
}
local EventClientImpl = {}
type EventClientObject = typeof(setmetatable(
	{} :: EventClientInternal,
	{ __index = EventClientImpl }
))

function EventClientImpl.send(self: EventClientObject, ...)
	table.insert(pktshareds.outcoming, {
		channel = self.channel,
		id = self.id,
		args = {...},
	})
end

function EventClientImpl.listen<A...>(self: EventClientObject, listener: EventClientCallback<A...>): (() -> ())
	local listener_id = self._internal.listener_count
	self._internal.listener_count += 1
	self._internal.listeners[listener_id] = listener

	return function()
		self._internal.listeners[listener_id] = nil
	end
end

function EventClientImpl.listenOnce<A...>(self: EventClientObject, listener: EventClientCallback<A...>): (() -> ())
	local disconnect_func
	local function listener_wrapper(...)
		(listener :: any)(...)
		disconnect_func()
	end

	disconnect_func = EventClientImpl.listen(self, listener_wrapper)
	return disconnect_func
end

function EventClientImpl.wait(self: EventClientObject): any
	local thread = coroutine.running()
	local disconnect_func

	local function listener_wrapper(...)
		disconnect_func()
		task.spawn(thread, ...)
	end

	disconnect_func = EventClientImpl.listen(self, listener_wrapper)
	return coroutine.yield()
end

function EventClientImpl.dispose(self: EventClientObject)
	table.clear(self._internal.listeners)
end

return function(channel: types.CommunicationChannelType, id: string): EventClientObject
	local self = setmetatable(
		{} :: EventClientInternal,
		{ __index = EventClientImpl }
	)

	self.id = id
	self.channel = channel
	self._internal = {
		listener_count = 1,
		listeners = {},
	}

	pktshareds.listeners[self.id] = function(sender: Player?, ...)
		for _, listener in self._internal.listeners do
			task.spawn(listener, sender, ...)
		end
	end

	return self
end
