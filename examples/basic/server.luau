local communiception = require("@communiception/src/server")
require("./shared")()

-- ok so event is only one way and u can define functions from the double wrapped symbols
local WaveEvent = communiception.event<<(string, number)>>("reliable", "OnWave")

-- while dis one is two way so u can return things after invocation
local IsGamerRPC = communiception.rpc<<(), (boolean)>>("GamerCheck")
local IsHackerRPC = communiception.rpc<<(), (boolean)>>("GamerMoneyBuy")

WaveEvent:listen(function(sender: Player, ...)
	print(`Player "{sender.Name}" said: {...}!`)
	
	local success, is_hax0r_confirmed = IsHackerRPC:invokeTo(sender, 10)
	if not success then
		print("failed to check if player is hax0r, kicking...")
		sender:Kick("rejoin")
		return
	end

	if is_hax0r_confirmed then
		print("ur hax0r kick time >:)")
		sender:Kick("ur hax0r die die die")
		return
	end

	print("he nono hax0r, let him cook!")
end)

IsGamerRPC:setListener(function(sender: Player): boolean
	return (math.random() > 0.5)
end)
