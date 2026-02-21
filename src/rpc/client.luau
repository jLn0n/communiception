local pktshareds = require("../pktshareds")

export type RPCClient<A..., R...> = {
	id: string,

	invoke: (self: RPCClient<A..., R...>, timeout: number, A...) -> (boolean, R...),
	setListener: (self: RPCClient<A..., R...>, (A...) -> (R...)) -> (),
	dispose: (self: RPCClient<A..., R...>) -> (),
}

type RPCClientInternal = {
	id: string,

	_internal: {
		callback: (...any) -> (...any),
		listener_count: number,
		listeners: {(invoked: boolean, ...any) -> ()},
	},
}
local RPCClientImpl = {}
type RPCClientObject = setmetatable<RPCClientInternal, {__index: typeof(RPCClientImpl)}>

function RPCClientImpl.invoke(self: RPCClientObject, timeout: number, ...): (boolean, ...any)
	local thread = coroutine.running()
	local received = false
	local id = self._internal.listener_count
	self._internal.listener_count += 1

	self._internal.listeners[id] = function(invoked: boolean, ...)
		received = true
		self._internal.listeners[id] = nil

		if invoked then
			task.spawn(thread, true, ...)
		else
			task.spawn(thread, false)
		end
	end

	task.delay(timeout, function()
		if received then
			-- callback is already recieved, cancel this automatic cancellation
			return
		end

		self._internal.listeners[id] = nil
		task.spawn(thread, false)
	end)

	table.insert(pktshareds.outcoming, {
		channel = "reliable" :: "reliable",
		id = self.id,
		args = {false, id, ...},
		targets = nil,
	})
	return coroutine.yield()
end

function RPCClientImpl.setListener<T>(self: RPCClientObject, callback: T)
	self._internal.callback = callback :: any
end

function RPCClientImpl.dispose(self: RPCClientObject)
	table.clear(self._internal.listeners)
end

return function(id: string): RPCClientObject
	local self = setmetatable(
		{} :: RPCClientInternal,
		{ __index = RPCClientImpl }
	)

	self.id = id
	self._internal = {
		callback = nil :: any,
		listener_count = 1,
		listeners = {},
	}

	-- mode: true as incoming | false as outcoming
	pktshareds.listeners[self.id] = (function(is_incoming: boolean, id: number, ...)
		if is_incoming then
			local listener = self._internal.listeners[id]
			if not listener then
				return
			end

			listener(...)
		else
			local callback = self._internal.callback
			local args: {any} = {true, id}

			if callback then
				args[3] = true
				local callback_rets = {callback(...)}

				table.move(callback_rets, 1, #callback_rets, 4, args)
				table.clear(callback_rets)
			else
				args[3] = false
			end

			table.insert(pktshareds.outcoming, {
				channel = "reliable" :: "reliable",
				id = self.id,
				args = args,
				targets = nil,
			})
		end
	end) :: any

	return self
end
