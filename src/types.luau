export type CommunicationChannelType = "reliable" | "unreliable"

export type CommuniceptionConfig = {
	PACKET_INTERVAL_HZ: number,

	CHANNELS_FETCH: () -> (RemoteEvent, UnreliableRemoteEvent),
	CHANNELS_CHANGED: () -> (boolean),

	IDENTIFIER_ENCRYPTION: IdentifierCrypterCallback,
	IDENTIFIER_DECRYPTION: IdentifierCrypterCallback,
}

export type CommuniceptionChannels = {
	[CommunicationChannelType]: BaseRemoteEvent,
	["reliable"]: RemoteEvent,
	["unreliable"]: UnreliableRemoteEvent,
}

export type IdentifierCrypterCallback = (id: string) -> (string)

return nil
