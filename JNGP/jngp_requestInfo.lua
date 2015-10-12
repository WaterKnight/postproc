local t = {}

t.getLastOutputPath = function(postprocDir)
	assert(postprocDir, 'no postprocDir stated')

	local tempDir = postprocDir..[[temp\]]

	local f = io.open(tempDir..'lastOutputPath.txt')

	if (f == nil) then
		return nil
	end

	local res = f:read('*a')

	f:close()

	return res
end

t.getVersion = function(postprocDir)
	assert(postprocDir, 'no postprocDir stated')

	local versionFilePath = postprocDir..'version.txt'

	local f = io.open(versionFilePath)

	assert(f, 'could not open '..versionFilePath)

	local res = f:read('*a')

	f:close()

	return res
end

return t