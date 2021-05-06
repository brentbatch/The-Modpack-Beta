--[[
	Copyright (c) 2019 Brent Batch
	Contact: Brent Batch#9261 on discord
]]--
dofile "SE_Loader.lua"


lavaball = class( globalscript )
lavaball.maxParentCount = 0
lavaball.maxChildCount = 0
lavaball.connectionInput = sm.interactable.connectionType.none
lavaball.connectionOutput = sm.interactable.connectionType.none
lavaball.colorNormal = sm.color.new( 0x009999ff  )
lavaball.colorHighlight = sm.color.new( 0x11B2B2ff  )
lavaball.poseWeightCount = 1


function lavaball.client_onCreate(self)
	self:client_attachScript("customFire")
	self.shooteffect = sm.effect.createEffect("flameslight", self.interactable)
	self.shooteffect:setOffsetRotation( sm.vec3.getRotation(sm.vec3.new( 0, 1, 0 ),sm.vec3.new( 0, 0, 1 )))
	self.shooteffect:start()
end


function lavaball.server_onCollision(self, othershape, collidePosition, velocity, othervelocity, normal)
	
	local impactVelocity = (velocity - othervelocity):length2()
	
	if impactVelocity > 5 and impactVelocity < 30 then
		self.network:sendToClients("client_emberEffect", collidePosition)
	elseif impactVelocity > 30 then
		self.network:sendToClients("client_BIGemberEffect", collidePosition)
	end
	
	
	if math.random2(5) <= 2 then -- "% of doing a fire = 2/5"
		local result = {valid = true} -- create a fake raycastresult for the fire lib.
		result.type = "terrainSurface"
		result.pointWorld = collidePosition
		result.normalWorld = normal
		if othershape then
			result.type = "body"
			result.getShape = function() return othershape end
			result.getBody = function() return othershape.body end
			result.normalLocal = normal
		end

		customFire.server_spawnFire(self, {
			position = collidePosition,
			velocity = velocity,
			raycast = result,
			priority = true
		})
	end
end


function lavaball.client_emberEffect(self, worldPosition)
	sm.particle.createParticle("lavaEmbers", worldPosition) -- optional extra: , rotation(quat), color

end

function lavaball.client_BIGemberEffect(self, worldPosition)
	sm.particle.createParticle("lavaEmbersBig", worldPosition) -- optional extra: , rotation(quat), color

end
