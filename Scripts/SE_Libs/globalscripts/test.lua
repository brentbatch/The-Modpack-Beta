
-- a SINGLE globalscript, this could be a script taking care of all fire instances, or all custom projectiles
test = class()
test.defaultValue = 123

function test.server_onCreate(self, ...)
	print('test.server_onCreate', self.defaultValue)
	self.defaultValue = 456
	print('params',...)
	self.network:sendToClients("client_callback", {'client_callback',123})
end
function test.client_callback(self, data)
	print('test.client_callback',data)
end

function test.client_onCreate(self, ...)
	print('test.client_onCreate', self.defaultValue)
	print('params',...)
	self.network:sendToServer("server_callback", {'server_callback',123})
end
function test.server_callback(self, data)
	print('test.server_callback',data)
end

function test.server_onFixedUpdate(self,dt)
	print("test.server_onFixedUpdate")

end

function test.client_onFixedUpdate(self,dt)
	print("test.client_onFixedUpdate")

end

function test.onDestroy(self)
	print('onDestroy')
end

-- add extra fire.whatever functions to create instances for this script to take care of:
-- heck you could put functions here that to disquise the globalscript ugly-ness: fire.client_onCreate = sm.globalScript.client_init

