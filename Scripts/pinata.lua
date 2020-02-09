dofile "SE_Loader.lua"

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
	self.requiredHits = math.random2(100,300) 	-- between 100 and 300, using default seed/1000 and time
end

function pinata.server_onCollision(self, othershape, collidePosition, velocity, othervelocity, normal)
	if (velocity - othervelocity):length2() > 50 then
		if othershape then
			self.requiredHits = self.requiredHits - math.random2(10,30) -- creation hit
		else
			self.requiredHits = self.requiredHits - math.random2(0,2) -- ground hit?
		end
	end
	self:server_tryExplode()
end

function pinata.server_onSledgehammer(self, ...)
	self.requiredHits = self.requiredHits - math.random2(5,20)
	self:server_tryExplode()
end

function pinata.server_onProjectile(self, ...)
	self.requiredHits = self.requiredHits - math.random2(1,5)
	self:server_tryExplode()
end

function pinata.server_tryExplode(self)
	if self.requiredHits <= 0 then 
		sm.physics.explode( self.shape.worldPosition, 0, 0, 2, 10, "Pinata - ExplosionSmall", self.shape)
		self.shape:destroyShape()
	end
end


