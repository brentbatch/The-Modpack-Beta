local version = 1

if (sm.__SE_Version._jsonreader or 0) >= version then return end
sm.__SE_Version._jsonreader = version

print("Loading jsonreader")


sm.jsonReader = {}

function sm.jsonReader.getDescription() -- warning: will crash if the json contains numbers bigger than a int32
	local success, message = pcall(sm.json.open,"$MOD_DATA/description.json")
	if not success then sm.log.error(message) end
	return success and message
end

function sm.jsonReader.readFile(file) -- warning: will crash if the json contains numbers bigger than a int32
	local success, message = pcall(sm.json.open,"$MOD_DATA/"..file)
	if not success then sm.log.error(message) end
	return success and message
end
