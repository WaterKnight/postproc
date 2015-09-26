local function script_path()
	local str = debug.getinfo(2, "S").source:sub(2)

	str = str:gsub('/', '\\')

	local dir = str:match("(.*\\)")

	if (dir == nil) then
		return ''
	end

	return dir
end

package.path = script_path()..'?.lua'..';'..package.path

require 'orient'

local postprocDir = orient.reduceFolder(orient.toAbsPath(script_path()))

local configPath = postprocDir..'postproc_getconfigs.lua'

local config = dofile(configPath)

local waterluaPath = orient.toAbsPath(config.assignments['waterlua'], orient.getFolder(configPath))

assert(waterluaPath, 'no waterlua path found')

orient.addPackagePath(waterluaPath)

orient.requireDir(waterluaPath)

local checkSumsPath = io.local_dir()..'checksums.txt'

local f = io.open(checkSumsPath, 'w+')

local files = io.getFiles(postprocDir, '*')

for _, path in pairs(files) do
	local shortPath = path:sub(postprocDir:len() + 1, path:len())

	if ((path ~= checkSumsPath) and (shortPath:sub(1, 1) ~= '.')) then
		require 'libmd5'

		local status, checkSum = md5.digest(path)

		if (status == 0) then
			print(string.format('write %s %s', shortPath, checkSum))
			f:write(checkSum, '\t', shortPath, '\n')
		else
			print(string.format('could not digest %s (%s)', shortPath, checkSum))
		end
	end
end

f:close()

os.execute('pause')