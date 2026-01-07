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
		listeners: {(...any) -> ()},
	},
}
local RPCServerImpl = {}
type RPCServerObject = typeof(setmetatable(
	{} :: RPCServerInternal,
	{ __index = RPCServerImpl }
))

function RPCServerImpl.invokeTo(self: RPCServerObject, target: Player, timeout: number, ...): (boolean, ...any)
	local thread = coroutine.running()
	local received = false
	local id = self._internal.listener_count
	self._internal.listener_count += 1

	self._internal.listeners[id] = function(sender: Player, callbackInvoked: boolean, ...)
		if target ~= sender then
			return
		end

		received = true
		self._internal.listeners[id] = nil

		if callbackInvoked then
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
		channel = "reliable" :: any,
		id = self.id,
		args = {1, id, ...},
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

	-- mode: 0 as incoming | 1 as outcoming
	pktshareds.listeners[self.id] = function(sender: Player, mode: number, id: number, ...)
		if mode == 0 then
			local listener = self._internal.listeners[id]
			if not listener then
				return
			end

			listener(sender, ...)
		elseif mode == 1 then
			local callback = self._internal.callback
			local args: {any} = {0, id}

			if callback then
				args[3] = true
				local callback_rets = {callback(sender, ...)}

				table.move(callback_rets, 1, #callback_rets, 4, args)
				table.clear(callback_rets)
			else
				args[3] = false
			end

			table.insert(pktshareds.outcoming, {
				channel = "reliable" :: any,
				id = self.id,
				args = args,
				targets = {sender},
			})
		end
	end

	return self
end
