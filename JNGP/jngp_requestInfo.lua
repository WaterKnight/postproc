local t = {}

t.getLastOutputPath = function(postprocDir)
	assert(postprocDir, 'no postprocDir stated')

	local f = io.open(postprocDir..'lastOutputPath.txt')

	if (f == nil) then
		return nil
	end

	local res = f:read('*a')

	f:close()

	return res
end

return t