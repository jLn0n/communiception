local pktshareds = require("../pktshareds")

export type RPCServer<A..., R...> = {
	id: string,

	invokeTo: (self: RPCServer<A..., R...>, target: Player, timeout: number, A...) -> (boolean, R...),
	setListener: (self: RPCServer<A..., R...>, (sender: Player, A...) -> (R...)) -> (),
	dispose: (self: RPCServer<A..., R...>) -> (),
}

type RPCServerInternal = {
	id: string,

	_internal: {
		callback: (...any) -> (...any),
		listener_count: number,
		listeners: {(sender: Player, invoked: boolean, ...any) -> ()},
	},
}
local RPCServerImpl = {}
type RPCServerObject = setmetatable<RPCServerInternal, {__index: typeof(RPCServerImpl)}>

function RPCServerImpl.invokeTo(self: RPCServerObject, target: Player, timeout: number, ...): (boolean, ...any)
	local thread = coroutine.running()
	local received = false
	local id = self._internal.listener_count
	self._internal.listener_count += 1

	self._internal.listeners[id] = function(sender: Player, invoked: boolean, ...)
		if target ~= sender then
			return
		end

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
		targets = {target},
	})
	return coroutine.yield()
end

function RPCServerImpl.setListener<T>(self: RPCServerObject, callback: T)
	self._internal.callback = callback :: any
end

function RPCServerImpl.dispose(self: RPCServerObject)
	table.clear(self._internal.listeners)
end

return function(id: string): RPCServerObject
	local self = setmetatable(
		{} :: RPCServerInternal,
		{ __index = RPCServerImpl }
	)

	self.id = id
	self._internal = {
		callback = nil :: any,
		listener_count = 1,
		listeners = {},
	}

	-- mode: true as incoming | false as outcoming
	pktshareds.listeners[self.id] = (function(sender: Player, is_incoming: boolean, id: number, ...)
		if is_incoming then
			local listener = self._internal.listeners[id]
			if not listener then
				return
			end

			listener(sender, ...)
		else
			local callback = self._internal.callback
			local args: {any} = {true, id}

			if callback then
				args[3] = true
				local callback_rets = {callback(sender, ...)}

				table.move(callback_rets, 1, #callback_rets, 4, args)
				table.clear(callback_rets)
			else
				args[3] = false
			end

			table.insert(pktshareds.outcoming, {
				channel = "reliable" :: "reliable",
				id = self.id,
				args = args,
				targets = {sender},
			})
		end
	end) :: any

	return self
end
