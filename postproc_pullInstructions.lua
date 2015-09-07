local params = {...}

local mapPath = params[1]
local openExplorer = params[2]

assert(mapPath, 'no mapPath')

assert(mapPath and mapPath:len() > 0, 'no mapPath')

require 'waterlua'

local function script_path()
	local str = debug.getinfo(2, "S").source:sub(2)

	str = str:gsub('/', '\\')

	local dir = str:match("(.*\\)")

	if (dir == nil) then
		return ''
	end

	return dir
end

--local mapRepo = postprocDir..[[temp\instructions\]]..getFileName(mapPath, true)..[[\]]
local mapRepo = mapPath..[[_postproc\]]

local indexTargetPath = mapRepo..[[_index.txt]]
local currentTargetPath = mapRepo..[[_current.txt]]

require 'portLib'

--local mapArchive = wehack.openarchive(mapPath)

--assert(mapArchive, 'cannot open map archive')

--wehack.extractfile([[postproc\instructions\index.txt]], indexTargetPath)

if not io.pathExists(mapRepo) then
	createDir(mapRepo)

	portLib.mpqExtract(mapPath, [[postproc\instructions\_index.txt]], indexTargetPath)
	portLib.mpqExtract(mapPath, [[postproc\instructions\_current.txt]], currentTargetPath)

	local f = io.open(indexTargetPath, 'r')

	if (f ~= nil) then
		local s = f:read('*a')

		for _, v in pairs(s:split('\n')) do
			if v:match('.+') then
				--wehack.extractfile([[postproc\instructions\]]..v..'.lua', mapRepo..v..'.lua')
				--portLib.mpqExtract(mapPath, [[postproc\instructions\]]..v..'.lua', mapRepo..v..'.lua')
				portLib.mpqExtract(mapPath, [[postproc\instructions\]]..v, mapRepo..v)
			end
		end

		f:close()
	end

	--wehack.closearchive(mapArchive)

	if createFile(currentTargetPath, false) then
		local f = io.open(currentTargetPath, 'w+')

		f:write([[release.lua]])

		f:close()
	end

	createFile(mapRepo..[[debug.lua]], false)
	createFile(mapRepo..[[release.lua]], false)
end

if (openExplorer == true) then
	os.execute('explorer '..mapRepo)
end