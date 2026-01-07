local pktshareds = require("@self/pktshareds")
local types = require("@self/types")

local IS_SERVER = game:GetService("RunService"):IsServer()

local communiception = {}

function communiception.initialize(config: types.CommuniceptionConfig): ()
	local PACKET_HZ = 1 / config.PACKET_INTERVAL_HZ
	local CHANNELS = {} :: types.CommuniceptionChannels

	local RBXSignalConnect = game.Changed.Connect
	local signal_name: "OnServerEvent" | "OnClientEvent" = nil :: any
	local remote_handlers = {} :: {["reliable"]: (...any) -> (), ["unreliable"]: (...any) -> ()}

	if IS_SERVER then
		signal_name = "OnServerEvent"
		remote_handlers.reliable = function(sender: Player, id: string, ...)
			table.insert(pktshareds.incoming, {
				channel = "reliable" :: any,
				id = id,
				args = {...},
				sender = sender
			})
		end
		remote_handlers.unreliable = function(sender: Player, id: string, ...)
			table.insert(pktshareds.incoming, {
				channel = "unreliable" :: any,
				id = id,
				args = {...},
				sender = sender
			})
		end
	else
		signal_name = "OnClientEvent"
		remote_handlers.reliable = function(id: string, ...)
			table.insert(pktshareds.incoming, {
				channel = "reliable" :: any,
				id = id,
				args = {...},
			})
		end
		remote_handlers.unreliable = function(id: string, ...)
			table.insert(pktshareds.incoming, {
				channel = "unreliable" :: any,
				id = id,
				args = {...},
			})
		end
	end

	local function onChannelsChange()
		local new_channels = {} :: types.CommuniceptionChannels
		new_channels.reliable, new_channels.unreliable = config.CHANNELS_FETCH()

		for channel_name, channel_obj in new_channels do
			local old_channel = CHANNELS[channel_name]
			if typeof(channel_obj) ~= "Instance" or channel_obj == old_channel then
				continue
			end

			CHANNELS[channel_name] = channel_obj
			RBXSignalConnect((channel_obj :: any)[signal_name], remote_handlers[channel_name])
		end

		table.clear(new_channels)
	end

	task.spawn(function()
		while true do task.wait(1/60)
			if not config.CHANNELS_CHANGED() then
				continue
			end

			onChannelsChange()
		end
	end)
	task.defer(onChannelsChange)
	task.spawn(pktshareds.processIncomingPackets, PACKET_HZ)
	task.spawn(pktshareds.processOutcomingPackets, PACKET_HZ, CHANNELS)
end

return communiception
