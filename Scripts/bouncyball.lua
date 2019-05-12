
-- ball.lua --
ball = class( nil )
ball.maxChildCount = 0
ball.maxParentCount = 0
ball.connectionInput = sm.interactable.connectionType.none
ball.connectionOutput = sm.interactable.connectionType.none
ball.colorNormal = sm.color.new( 0xcb0a00ff )
ball.colorHighlight = sm.color.new( 0xee0a00ff )

function ball.server_onCreate(self)
	self.lastcollision = os.clock()
	self.bounce = 0.7
	if self.data and self.data.bounce then -- overwrite bouncyness if data preset in json
		self.bounce = seld.data.bounce/100
	end
end


function ball.server_onCollision( self, other, position, velocity, otherVelocity ) 
	local rotatearound = (position- self.shape.worldPosition):normalize()
	
	local pulse = sm.vec3.rotate( velocity*-1, math.rad(180), rotatearound )
	
	if (os.clock() - self.lastcollision)>0.4 then
		sm.physics.applyImpulse(self.shape, pulse*self.shape.mass*self.bounce, true)
	end
	self.lastcollision = os.clock()
end