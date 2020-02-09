
-- better random function:
-- usage: 
--		math.random2()			returns: random number between 0 and 100
--		math.random2(13)		returns: random number between 0 and 13
--		math.random2(13,4)		returns: random number between 4 and 13
--		math.random2(4,13)		returns: random number between 4 and 13
function math.random2(arg1, arg2) 
	arg1 = arg1 or 100
	arg2 = arg2 or 0
	if arg1 > arg2 then -- first was max
		return (math.random(69420) * os.time()) % (arg1 - arg2) + arg2
	elseif arg2 > arg1 then -- first was min
		return (math.random(69420) * os.time()) % (arg2 - arg1) + arg1
	else -- they are equal, someone didn't use this properly
		return (math.random(69420) * os.time()) % arg1
	end
end