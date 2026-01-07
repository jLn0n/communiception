local communiception = require("@communiception/src")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SAMPLE_ID_KEY = buffer.fromstring("hi gamers its me!")

local function XOR(msg: string, key_buffer: buffer): string
	local msg_length, key_length = #msg, buffer.len(key_buffer)
	local msg_buffer = buffer.fromstring(msg)
	local result = buffer.create(msg_length)

	for idx = 0, msg_length - 1 do
		buffer.writeu8(result, idx, bit32.bxor(
			buffer.readu8(msg_buffer, idx),
			buffer.readu8(key_buffer, idx % key_length)
		))
	end
	return buffer.tostring(result)
end

local config: communiception.CommuniceptionConfig = {
	PACKET_INTERVAL_HZ = 60,

	-- u can create ur own remotes here and perhaps add anti-destroy on this two remotes
	CHANNELS_CHANGED = function()
		return false
	end,
	CHANNELS_FETCH = function()
		local reliable, unreliable = Instance.new("RemoteEvent"), Instance.new("UnreliableRemoteEvent")
		reliable.Parent, unreliable.Parent = ReplicatedStorage, ReplicatedStorage

		return reliable, unreliable
	end,

	-- you can do whatever u want here like modify id to be like shorter or different or just return as-is
	IDENTIFIER_ENCRYPTION = function(id: string)
		return XOR(id, SAMPLE_ID_KEY)
	end,
	IDENTIFIER_DECRYPTION = function(id: string)
		return XOR(id, SAMPLE_ID_KEY)
	end
}

return config
