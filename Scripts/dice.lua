
dice = class()
dice.maxParentCount = 0
dice.maxChildCount = 0
dice.connectionInput = sm.interactable.connectionType.none
dice.connectionOutput = sm.interactable.connectionType.none
dice.colorNormal = sm.color.new( 0x009999ff  )
dice.colorHighlight = sm.color.new( 0x11B2B2ff  )
dice.poseWeightCount = 3

-- self.shape.at = sky
-- right = right
-- up = towards

function dice.client_onCreate(self)
	self.dicepos_x = 0
	self.dicepos_y = 0
	self.momentum_x = 0
	self.momentum_y = 0
end

function dice.client_onRefresh(self)
	self.dicepos_x = 0
	self.dicepos_y = 0
	self.momentum_x = 2.5
	self.momentum_y = 0
end

function dice.client_onUpdate(self, dt)
	self.dicepos_x = self.dicepos_x + self.momentum_x * 0.99 * dt
	self.momentum_x = self.momentum_x*0.99 + (self.dicepos_x < 0 and 3 or -3) * dt
	
	local up = self.shape.at
	
	self.angular_speed_up = (up - (self.last_up or up))/dt -- speed-ish (hacky)
	self.last_up = up
	
	self.angular_acc_up = (self.angular_speed_up - (self.last_angular_speed_up or self.angular_speed_up))/dt -- acceleration-ish
	self.last_angular_speed_up = self.angular_speed_up
	
	self.dir_right = up.y
	self.dir_top = up.x
	
	self.interactable:setPoseWeight(1, sm.util.clamp(( self.dicepos_x+1)/1.7, 0,1))
	self.interactable:setPoseWeight(0, sm.util.clamp((-self.dicepos_y+1)/1.7, 0,1))

	if os.time() ~= self.time and false then
		self.time = os.time()
		self.interactable:setPoseWeight(0, self.time%4 == 0 and 1 or 0)
		self.interactable:setPoseWeight(1, self.time%4 == 1 and 1 or 0)
		self.interactable:setPoseWeight(2, self.time%4 == 2 and 1 or 0)
		print(self.time%3)
	end

end