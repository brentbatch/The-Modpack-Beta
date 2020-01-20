
pinata = class( nil )
pinata.maxParentCount = 0
pinata.maxChildCount = 0
pinata.connectionInput = sm.interactable.connectionType.none
pinata.connectionOutput = sm.interactable.connectionType.none
pinata.colorNormal = sm.color.new( 0x009999ff  )
pinata.colorHighlight = sm.color.new( 0x11B2B2ff  )
pinata.poseWeightCount = 1


function pinata.server_onCreate(self)
	local chance = math.random(1,50)
	if chance == 1 then -- below 10 range
		self.requiredHits = math.random(1,10)
	elseif chance == 2 then -- between 20 and 30
		self.requiredHits = math.random(20,30)
	else -- 10-20 range
		self.requiredHits = math.random(10,20)
	end
end

function pinata.server_onCollision(self, othershape, collidePosition, velocity, othervelocity, normal)
	if (velocity - othervelocity):length2() > 50 then
		self.requiredHits = self.requiredHits - 1
	end
	self:server_tryExplode()
end

function pinata.server_onSledgehammer(self, ...)
	self.requiredHits = self.requiredHits - 1
	self:server_tryExplode()
end

function pinata.server_onProjectile(self, ...)
	self.requiredHits = self.requiredHits - 1
	self:server_tryExplode()
end

function pinata.server_tryExplode(self)
	if self.requiredHits <= 0 then 
		sm.physics.explode( self.shape.worldPosition, 0, 0, 2, 10, "CornShot - ExplosionSmall", self.shape)
		self.shape:destroyShape()
	end
end
