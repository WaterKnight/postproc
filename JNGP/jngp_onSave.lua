local params = {...}

local config = params[1]
local paramsMap = params[2]

assert(config, 'no config')
assert(paramsMap, 'no paramsMap')

local mapPath = paramsMap['mapPath']
local outputPathNoExt = paramsMap['outputPathNoExt']

assert(mapPath, 'no mapPath')
assert(outputPathNoExt, 'no outputPathNoExt')

local ext = mapPath:match('%.[^%..]*$') or ''

local outputPath = outputPathNoExt..ext

local postprocDir = paramsMap['postprocDir']

assert(postprocDir, 'no postprocDir')

local postprocPath = postprocDir..'postproc.lua'

assert(postprocPath, 'no postprocPath')

local postproc, loadErr = loadfile(postprocPath)

assert(postproc, 'cannot load '..tostring(postprocPath)..'\n'..tostring(loadErr))

local function toLua(val)
	if (val == nil) then
		return 'nil'
	end

	if (type(val) == 'boolean') then
		if (val == true) then
			return 'true'
		end

		return 'false'
	end
	if (type(val) == 'string') then
		return string.format('%q', val)
	end

	return nil
end

local s = [[
	local mapPath = ]]..toLua(mapPath)..[[
	local outputPath = ]]..toLua(outputPath)..[[
	local wc3path = ]]..toLua(paramsMap['wc3path'])..[[
	local configPath = ]]..toLua(paramsMap['configPath'])..[[
	local logPath = ]]..toLua(paramsMap['logPath'])..[[
	local useConsoleLog = ]]..toLua(paramsMap['useConsoleLog'])..[[

	local postprocPath = ]]..toLua(postprocPath)..[[

	local postproc, loadErr = loadfile(postprocPath)

	assert(postproc, 'cannot load '..tostring(postprocPath)..'\n'..tostring(loadErr))

	return postproc(mapPath, outputPath, nil, wc3path, configPath, logPath, useConsoleLog)
]]

localDir = debug.getinfo(1, 'S').source:sub(2):match('(.*'..'\\'..')')

local function addPackagePath(path)
	assert(path, 'no path')

	local luaPath = path..'.lua'

	if not package.path:match(luaPath) then
		package.path = package.path..';'..luaPath
	end

	local dllPath = path..'.dll'

	if not package.path:match(dllPath) then
		package.cpath = package.cpath..';'..dllPath
	end
end

addPackagePath(localDir..'?')
addPackagePath(localDir..'?\\init')
addPackagePath(localDir..'?\\?')

require 'rings'

local sub = rings.new(t)

local function pack(...)
	return arg
end

local results = pack(sub:dostring(s))

local success = results[1]

if not success then
	local msg = results[2]
	local trace = results[3]

	error(msg)

	return false
end

local noDefaultTools = results[3]

return true, noDefaultTools