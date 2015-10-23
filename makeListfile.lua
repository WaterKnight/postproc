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

local postprocDir = orient.toAbsPath(script_path())

local configPath = postprocDir..'postproc_getconfigs.lua'

local config = dofile(configPath)

local waterluaPath = orient.toAbsPath(config.assignments['waterlua'], orient.getFolder(configPath))

assert(waterluaPath, 'no waterlua path found')

orient.addPackagePath(waterluaPath)

orient.requireDir(waterluaPath)

local listfilePath = io.local_dir()..'listfile.txt'

local f = io.open(listfilePath, 'w+')

f:write('path\tmd5\t\n')

f:write('---------------------\n')

local files = io.getFiles(postprocDir, '*')

for _, path in pairs(files) do
	local shortPath = path:sub(postprocDir:len() + 1, path:len())

	if ((path ~= listfilePath) and (shortPath:sub(1, 1) ~= '.')) then
		require 'libmd5'

		local status, checksum = md5.digest(path)

		if (status == 0) then
			print(string.format('write %s %s', shortPath, checksum))
			f:write(shortPath, '\t', checksum, '\n')
		else
			print(string.format('could not digest %s (%s)', shortPath, checksum))
		end
	end
end

f:close()

os.execute('pause')