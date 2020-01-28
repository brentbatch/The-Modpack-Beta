dofile "SE_Loader.lua"

-- the following code prevents re-load of this file, except if in '-dev' mode.
if stickyGrenade and not sm.isDev then -- increases performance for non '-dev' users.
	return -- perform sm.checkDev(shape) in server_onCreate to set sm.isDev
end 


stickyGrenade = class( globalscript )
stickyGrenade.maxParentCount = 1
stickyGrenade.maxChildCount = 0
stickyGrenade.connectionInput = sm.interactable.connectionType.logic
stickyGrenade.connectionOutput = sm.interactable.connectionType.none
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
	local parent = self.interactable:getSingleParent()
	local active = parent and parent.active
	
	if active and not self.timeout then
		active = false
		self.timeout = 20
		stickyBomb.server_spawnBomb(self.shape.worldPosition, -self.shape.right*50, 10)
	end
	
	if self.timeout then -- lazy way to generate timeout
		self.timeout = self.timeout - 1
		if self.timeout < 0 and not active then
			self.timeout = nil
		end
	end
end
