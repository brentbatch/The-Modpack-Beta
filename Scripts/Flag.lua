-- Copyright (c) 2018 Lord Pain --

-- Flag.lua --

Flag = class( nil )
Flag.maxChildCount = 0
Flag.maxParentCount = 1
Flag.connectionInput = sm.interactable.connectionType.none
Flag.connectionOutput = sm.interactable.connectionType.none
Flag.colorNormal = sm.color.new( 0xcb0a00ff )
Flag.colorHighlight = sm.color.new( 0xee0a00ff )
Flag.poseWeightCount = 1
Flag.animSpeed = 2


function Flag.server_onCreate( self ) 
	self:server_init()
end

function Flag.server_init( self ) 

end

function Flag.server_onRefresh( self )
	self:server_init()
end

function Flag.server_onFixedUpdate( self, timeStep )
	
end


-- Client

function Flag.client_onCreate( self )
	self.poseWeight = 0.0
	self.prevposeWeight = 0.00001
end

function Flag.client_onUpdate( self, dt )
	local rnd = math.random(0.1, 1)
	if self.poseWeight > self.prevposeWeight and self.poseWeight < 1 then
		self.prevposeWeight = self.poseWeight
		self.poseWeight = self.poseWeight + dt * self.animSpeed * rnd
		else
			if self.poseWeight >= 1 then
				self.prevposeWeight = 1
				self.poseWeight = 1 - dt * self.animSpeed * rnd
			end
	end
	
	if self.poseWeight < self.prevposeWeight and self.poseWeight > 0 then
		self.prevposeWeight = self.poseWeight
		self.poseWeight = self.poseWeight - dt * self.animSpeed * rnd
		else
			if self.poseWeight <= 0 then
				self.prevposeWeight = 0
				self.poseWeight = 0 + dt * self.animSpeed * rnd
			end
	end
	self.interactable:setPoseWeight( 0, self.poseWeight )
	
end
