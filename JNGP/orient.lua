function script_path()
	local str = debug.getinfo(2, "S").source:sub(2)

	str = str:gsub('/', '\\')

	local dir = str:match("(.*\\)")

	if (dir == nil) then
		return ''
	end

	return dir
end

package.cpath = script_path()..'?.dll'..';'..package.cpath

require 'lfs'

function addPackagePath(path)
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

function requireDir(path)
	assert(path, 'no path')

	path = path:gsub('/', '\\')

	local dir, name = path:match("(.*\\)(.*)")

	if (dir ~= nil) then
		local add = dir..'?\\init'

		addPackagePath(add)

		local add = path..'\\?'

		addPackagePath(add)
	end

	package.loaded[name] = nil

	require(name)
end

local isAbsPath = function(path)
	assert(path, 'no path')

	if path:find(':') then
		return true
	end

	return false
end

io.isAbsPath = function(path)
	return isAbsPath(path)
end

local function toFolderPath(path)
	assert(path, 'no path')

if type(path)=='number' then
	error(debug.traceback())
end
	path = path:gsub('/', '\\')

	if not path:match('\\$') then
		path = path..'\\'
	end

	return path
end

function getFolder(path)
	assert(path, 'no path')

	local res = ""

	while path:find("\\") do
		res = res..path:sub(1, path:find("\\"))

		path = path:sub(path:find("\\") + 1)
	end

	return res
end

function getFileName(path, noExtension)
	assert(path, 'no path')

	while path:find("\\") do
		path = path:sub(path:find("\\") + 1)
	end

	if noExtension then
		if path:lastFind('%.') then
			path = path:sub(1, path:lastFind('%.') - 1)
		end
	end

	return path
end

string.reduceFolder = function(s, amount)
	if (amount == nil) then
		amount = 1
	end

	if (amount == 0) then
		return s
	end

	return string.reduceFolder(getFolder(s:sub(1, getFolder(s):len() - 1))..getFileName(s), amount - 1)
end

local toAbsPath = function(path, basePath)
	assert(path, 'no path')

	path = path:gsub('/', '\\')

	if isAbsPath(path) then
		return path
	end

	--local scriptDir = getFolder(scriptPath:gsub('/[^/]+$', ''))

	if (basePath == nil) then
		basePath = io.curDir()
	end

	local result = toFolderPath(basePath)

	while (path:find('..\\', 1, true) == 1) do
		result = result:reduceFolder()

		path = path:sub(4)
	end

	result = result..path

	return result
end

io.toAbsPath = function(path, basePath)
	return toAbsPath(path, basePath)
end

io.curDir = function()
	return toFolderPath(lfs.currentdir())
end

local function getCallStack()
	local t = {}

	local c = 2

	while debug.getinfo(c, 'S') do
		local what = debug.getinfo(c, 'S').what

		if ((what == 'Lua') or (what == 'main')) then
			t[#t + 1] = debug.getinfo(c, 'S')
		end

		c = c + 1
	end

	return t
end

io.local_dir = function(level)
	if (level == nil) then
		level = 0
	end

	local path = getCallStack()[2 + level].source

	path = path:match('^@(.*)$')

	while ((path:find('.', 1, true) == 1) or (path:find('\\', 1, true) == 1)) do
		path = path:sub(2)
	end

	path = path:gsub('/', '\\')

	path = path:match('(.*\\)') or ''

	if not io.isAbsPath(path) then
		path = io.curDir()..path
	end

	return path
end