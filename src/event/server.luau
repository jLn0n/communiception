local pktshareds = require("../pktshareds")
local types = require("../types")

type EventServerCallback<A...> = (sender: Player, A...) -> ()
export type EventServer<A...> = {
	id: string,
	channel: types.CommunicationChannelType,

	sendTo: (self: EventServer<A...>, target: Player, A...) -> (),
	sendToMultiple: (self: EventServer<A...>, targets: {Player}, A...) -> (),
	listen: (self: EventServer<A...>, EventServerCallback<A...>) -> (() -> ()),
	listenOnce: (self: EventServer<A...>, EventServerCallback<A...>) -> (() -> ()),
	wait: (self: EventServer<A...>) -> (A...),
	dispose: (self: EventServer<A...>) -> (),
}

type EventServerInternal = {
	id: string,
	channel: types.CommunicationChannelType,

	_internal: {
		listener_count: number,
		listeners: {EventServerCallback<...any>},
	},
}
local EventServerImpl = {}
type EventServerObject = typeof(setmetatable(
	{} :: EventServerInternal,
	{ __index = EventServerImpl }
))

function EventServerImpl.sendTo(self: EventServerObject, target: Player, ...)
	table.insert(pktshareds.outcoming, {
		channel = self.channel,
		id = self.id,
		args = {...},
		targets = {target},
	})
end

function EventServerImpl.sendToMultiple(self: EventServerObject, targets: {Player}, ...)
	table.insert(pktshareds.outcoming, {
		channel = self.channel,
		id = self.id,
		args = {...},
		targets = targets,
	})
end

function EventServerImpl.listen<A...>(self: EventServerObject, listener: EventServerCallback<A...>): (() -> ())
	local listener_id = self._internal.listener_count
	self._internal.listener_count += 1
	self._internal.listeners[listener_id] = listener

	return function()
		self._internal.listeners[listener_id] = nil
	end
end

function EventServerImpl.listenOnce<A...>(self: EventServerObject, listener: EventServerCallback<A...>): (() -> ())
	local disconnect_func
	local function listener_wrapper(...)
		(listener :: any)(...)
		disconnect_func()
	end

	disconnect_func = EventServerImpl.listen(self, listener_wrapper)
	return disconnect_func
end

function EventServerImpl.wait(self: EventServerObject): any
	local thread = coroutine.running()
	local disconnect_func

	local function listener_wrapper(...)
		disconnect_func()
		task.spawn(thread, ...)
	end

	disconnect_func = EventServerImpl.listen(self, listener_wrapper)
	return coroutine.yield()
end

function EventServerImpl.dispose(self: EventServerObject)
	table.clear(self._internal.listeners)
end

return function(channel: types.CommunicationChannelType, id: string): EventServerObject
	local self = setmetatable(
		{} :: EventServerInternal,
		{ __index = EventServerImpl }
	)

	self.id = id
	self.channel = channel
	self._internal = {
		listener_count = 1,
		listeners = {},
	}

	pktshareds.listeners[self.id] = function(sender: Player, ...)
		for _, listener in self._internal.listeners do
			task.spawn(listener, sender, ...)
		end
	end

	return self
end

