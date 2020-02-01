

-- better random function:
function math.random2(arg1, arg2) -- arg1 is min
	arg1 = arg1 or 100
	arg2 = arg2 or 0
	return (math.random(1000) * os.time()) % (arg1 - arg2) + arg2
end
