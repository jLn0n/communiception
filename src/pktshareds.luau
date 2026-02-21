local types = require("./types")

local IS_SERVER = game:GetService("RunService"):IsServer()

type CommonPacket = {
	channel: types.CommunicationChannelType,
	id: string,
	args: {any},
}

export type IncomingPacket = CommonPacket & {
	sender: Player?,
}

export type OutcomingPacket = CommonPacket & {
	targets: {Player}?
}

local module = {
	incoming = {} :: {IncomingPacket},
	outcoming = {} :: {OutcomingPacket},
	
	listeners = {} :: {[string]: <A...>(A...) -> ()},
}

function module.processIncomingPackets(
	hz: number,
	id_decrypter: types.IdentifierCrypterCallback
)
	while true do task.wait(hz)
		local packet = module.incoming[1]
		if not packet then
			continue
		end

		local listener = module.listeners[id_decrypter(packet.id)]
		if not listener then
			continue
		end

		table.remove(module.incoming, 1)

		if IS_SERVER then
			if not packet.sender then
				continue
			end

			task.spawn(listener, packet.sender, unpack(packet.args))
		else
			task.spawn(listener, unpack(packet.args))
		end
	end
end

function module.processOutcomingPackets(
	hz: number,
	id_encrypter: types.IdentifierCrypterCallback,
	channels: types.CommuniceptionChannels
)
	while true do task.wait(hz)
		local packet = module.outcoming[1]
		if not packet then
			continue
		end

		local channel = channels[packet.channel]
		if not ((typeof)(channel) == "Instance" and channel:IsDescendantOf(game)) then
			continue
		end

		table.remove(module.outcoming, 1)

		local packet_id = id_encrypter(packet.id)

		if IS_SERVER then
			if (not packet.targets) then
				continue
			end

			for _, target in packet.targets do
				(channel :: any):FireClient(target, packet_id, unpack(packet.args))
			end
		else
			(channel :: any):FireServer(packet_id, unpack(packet.args))
		end
	end
end

return module
