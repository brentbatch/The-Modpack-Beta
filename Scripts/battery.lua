
-- battery.lua --
battery = class( nil )
battery.maxChildCount = -1
battery.maxParentCount = -1
battery.connectionInput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power
battery.connectionOutput = sm.interactable.connectionType.power
battery.colorNormal = sm.color.new( 0x844040ff )
battery.colorHighlight = sm.color.new( 0xb25959ff )

function battery.server_onCreate(self)
	self.charged = 100
	self.rate = 1
	self.userload = 0
end

function battery.server_onFixedUpdate(self, dt)
	local parents = self.interactable:getParents()
	local rate = nil
	local usage = nil
	local users = 0
	local charging = false
	
	for k, v in pairs(parents) do 
		if v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" --[[tickbutton]] 
			and tostring(v:getShape():getShapeUuid()) ~= "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orient block]] then 
			-- number
			if not rate then rate = 0 end
			rate = rate + v.power
			
		elseif v:getType() == "steering" or tostring(v:getShape():getShapeUuid()) == "ccaa33b6-e5bb-4edc-9329-b40f6efe2c9e" --[[orient block]] then
			if not usage then usage = 0 end
			usage = usage + v.power
			users = users + 1		
		else
			--logic
			if v:isActive() then charging = true end
		
		end
	end
	if users > 0 then usage = usage / users end
	if rate then self.rate = rate end
	
	if usage and usage ~= 0 and self.charged > 0 then
		local worsewhenlow = (self.charged)*3/400 + 0.25
		self.interactable.power = usage*worsewhenlow
		self.charged = self.charged - math.abs(usage*self.rate*self.userload)*dt*worsewhenlow
	else
		self.interactable.power = self.interactable.power/1.2
	end
	if charging and self.charged < 100 then
		local worsewhenlow = (self.charged)/200 + 0.5
		self.charged = self.charged + self.rate*dt*worsewhenlow
	end
end


function battery.client_onFixedUpdate(self, dt)
	if sm.isHost then 
		local children = self.interactable:getChildren()
		local userload = 0
		for k, v in pairs(children) do
			if v:getType() ~= "electricEngine" and v:getType() ~= "gasEngine" then
				userload = userload + v:getPoseWeight(0)
			else userload = userload + 1 end
		end
		self.userload = userload
	end
end