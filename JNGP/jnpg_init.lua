local params = {...}

local wehackVersion = params[1]

assert(wehackVersion, 'no wehack version')

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

local f = loadfile(io.local_dir()..'createWehackLua.lua')

if (f ~= nil) then
	--f()
end

local wehackPath = io.local_dir()..string.format('%s\\wehack.lua', wehackVersion)

dofile(wehackPath)