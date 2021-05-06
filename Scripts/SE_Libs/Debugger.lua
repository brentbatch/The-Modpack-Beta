--[[
	Copyright (c) 2019 Scrap Essentials Team
]]--


local classO = class
function class(...) -- multi-class inheritance, by Brent Batch
	local klass = {}
	for _, super in pairs({...}) do
		for k, v in pairs(super) do
			klass[k] = v
		end
	end
	return classO(klass)
end

local printO = print
function print(...) -- fancy print by TechnologicNick
	printO("[" .. sm.game.getCurrentTick() .. "]", sm.isServerMode() and "[Server]" or "[Client]", ...)
end