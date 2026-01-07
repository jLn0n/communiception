export type CommunicationChannelType = "reliable" | "unreliable"

export type CommuniceptionConfig = {
	PACKET_INTERVAL_HZ: number,

	CHANNELS_FETCH: () -> (RemoteEvent, UnreliableRemoteEvent),
	CHANNELS_CHANGED: () -> (boolean),
}

export type CommuniceptionChannels = {
	["reliable"]: RemoteEvent,
	["unreliable"]: UnreliableRemoteEvent,
}

return nil
