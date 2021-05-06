--[[
	Copyright (c) 2019 Brent Batch
	Contact: Brent Batch#9261 on discord
]]--
dofile "SE_Loader.lua"



stickyGrenade = class( globalscript )
stickyGrenade.maxParentCount = -1
stickyGrenade.maxChildCount = 1
stickyGrenade.connectionInput = sm.interactable.connectionType.logic
stickyGrenade.connectionOutput = sm.interactable.connectionType.power -- outputs bombs out there
stickyGrenade.colorNormal = sm.color.new( 0x009999ff  )
stickyGrenade.colorHighlight = sm.color.new( 0x11B2B2ff  )
stickyGrenade.poseWeightCount = 1

function stickyGrenade.client_onRefresh(self)
	self:client_onCreate()
end
function stickyGrenade.client_onCreate(self)
	self:client_attachScript("stickyBomb")
end


function stickyGrenade.server_onFixedUpdate(self, dt)
	local parents = self.interactable:getParents()
	local active = false
	local timeToDetonate = 10
	local capacity = 5
	
	
	for k, v in pairs(parents) do
		local color = tostring(v:getShape().color)
		
		if v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" --[[tickbutton]] then
			-- number
			if color == "eeeeeeff" then -- white: capacity
				capacity = math.floor(v.power) -- not using getValue here cuz won't be a big number
			elseif color == "222222ff" then -- black: detonation timeToDetonate
				timeToDetonate = v.power -- negative will insta detonate, pretty useless but i'll allow it.
			end
		elseif v.active then
			-- active logic 
			if color == "222222ff" then -- black
				stickyBomb.server_clearBombs(self.shape.id) -- explosive clear by default, add param 'false' for non explosive clear
				self.timeout = 1
				break -- break the for loop
			else
				active = true
			end
		end
	end
	
	if active and not self.timeout then
		active = false
		self.timeout = 1
		stickyBomb.server_spawnBomb(self.shape.id, self.shape.worldPosition, -self.shape.right*50, timeToDetonate, capacity)
	end
	
	if self.timeout then -- lazy way to generate timeout
		self.timeout = self.timeout - 1
		if self.timeout < 0 and not active then
			self.timeout = nil
		end
	end
end

