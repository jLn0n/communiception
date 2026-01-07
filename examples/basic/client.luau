local communiception = require("@communiception/src/client")

-- ok so event is only one way and u can define functions from the double wrapped symbols
local WaveEvent = communiception.event<<(string, number)>>("reliable", "OnWave")

-- while dis one is two way so u can return things after invocation
local IsGamerRPC = communiception.rpc<<(), (boolean)>>("GamerCheck")
local IsHackerRPC = communiception.rpc<<(), (boolean)>>("GamerMoneyBuy")

task.spawn(function()
	WaveEvent:send("communiception on client", 6767)

	local success, is_gamer_confirmed = IsGamerRPC:invoke(5)
	if not success then
		print("failed to do gamer check :(")
		return
	end
	
	print(`am I a gamer: {is_gamer_confirmed}`)
end)

IsHackerRPC:setListener(function(): boolean
	return not (game :: any).FilteringEnabled
end)
