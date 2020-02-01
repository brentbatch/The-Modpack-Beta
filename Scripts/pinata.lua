dofile "SE_Loader.lua"

-- the following code prevents re-load of this file, except if in '-dev' mode.
if pinata and not sm.isDev then -- increases performance for non '-dev' users.
	return -- perform sm.checkDev(shape) in server_onCreate to set sm.isDev
end 


pinata = class( nil )
pinata.maxParentCount = 0
pinata.maxChildCount = 0
pinata.connectionInput = sm.interactable.connectionType.none
pinata.connectionOutput = sm.interactable.connectionType.none
pinata.colorNormal = sm.color.new( 0x009999ff  )
pinata.colorHighlight = sm.color.new( 0x11B2B2ff  )
pinata.poseWeightCount = 1


function pinata.server_onCreate(self)
	--math.randomseed(os.time()) -- repair random predictability? (not available in this version of lua apparently)
	self.requiredHits = math.random2(300,100)-- (math.random(1,1000)+os.time())%200+100 	-- between 100 and 300, using default seed/1000 and time
end

function pinata.server_onCollision(self, othershape, collidePosition, velocity, othervelocity, normal)
	if (velocity - othervelocity):length2() > 50 then
		if othershape then
			self.requiredHits = self.requiredHits - math.random2(30,10)--(math.random(1,1000)+os.time())%20+10 -- creation hit
		else
			self.requiredHits = self.requiredHits - math.random2(2)--(math.random(1,1000)+os.time())%2 -- ground hit?
		end
	end
	self:server_tryExplode()
end

function pinata.server_onSledgehammer(self, ...)
	self.requiredHits = self.requiredHits - math.random2(20,15) -- (math.random(1,1000)+os.time())%15+5
	self:server_tryExplode()
end

function pinata.server_onProjectile(self, ...)
	self.requiredHits = self.requiredHits - math.random2(6,1)--(math.random(1,1000)+os.time())%5+1
	self:server_tryExplode()
end

function pinata.server_tryExplode(self)
	if self.requiredHits <= 0 then 
		sm.physics.explode( self.shape.worldPosition, 0, 0, 2, 10, "Pinata - ExplosionSmall", self.shape)
		self.shape:destroyShape()
	end
end


--	function randomNumber(min,max)
--	return (math.random(1,1000)+os.time())%(max-min)+min
--	helps to get a less predictable number, easy to set min max range (ignore math.random range)
