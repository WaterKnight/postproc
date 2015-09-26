--generated instruction file caller (D:\crig\abc.w3x_postproc\release.lua)
package.path = "D:\\Warcraft III\\Mapping\\postproc\\?.lua;;.\\?.lua;D:\\Warcraft III\\lua\\?.lua;D:\\Warcraft III\\lua\\?\\init.lua;D:\\Warcraft III\\?.lua;D:\\Warcraft III\\?\\init.lua;C:\\Program Files (x86)\\Lua\\5.1\\lua\\?.luac;D:\\Warcraft III\\Mapping\\postproc\\?.lua;D:\\Warcraft III\\Mapping\\?\\init.lua;D:\\Warcraft III\\Mapping\\waterlua\\?.lua;D:\\Warcraft III\\Mapping\\waterlua\\luaSocket\\?.lua;D:\\Warcraft III\\Mapping\\waterlua\\luaSocket\\lua\\?.lua;D:\\Warcraft III\\Mapping\\?\\init.lua;D:\\Warcraft III\\Mapping\\wc3libs\\?.lua;D:\\Warcraft III\\Mapping\\wc3libs\\?.lua;D:\\Warcraft III\\Mapping\\wc3libs\\?\\init.lua;D:\\Warcraft III\\Mapping\\wc3libs\\?\\?.lua"package.cpath = "D:\\Warcraft III\\Mapping\\postproc\\?.dll;.\\?.dll;.\\?51.dll;D:\\Warcraft III\\?.dll;D:\\Warcraft III\\?51.dll;D:\\Warcraft III\\clibs\\?.dll;D:\\Warcraft III\\clibs\\?51.dll;D:\\Warcraft III\\loadall.dll;D:\\Warcraft III\\clibs\\loadall.dll;D:\\Warcraft III\\Mapping\\postproc\\?.dll;D:\\Warcraft III\\Mapping\\?\\init.dll;D:\\Warcraft III\\Mapping\\waterlua\\?.dll;D:\\Warcraft III\\Mapping\\waterlua\\luaSocket\\?.dll;D:\\Warcraft III\\Mapping\\waterlua\\luaSocket\\lua\\?.dll;D:\\Warcraft III\\Mapping\\?\\init.dll;D:\\Warcraft III\\Mapping\\wc3libs\\?.dll;D:\\Warcraft III\\Mapping\\wc3libs\\?.dll;D:\\Warcraft III\\Mapping\\wc3libs\\?\\init.dll;D:\\Warcraft III\\Mapping\\wc3libs\\?\\?.dll"
require 'portLib'

local func = loadfile("D:\\crig\\abc.w3x_postproc\\release.lua")

local xpfunc = function()
	local args = {}

	return func(unpack(args))
end

local errorHandler = function(msg)
	local trace = debug.traceback('', 2):sub(2)

	local cmd = string.format('toolError(%q, %q)', msg, trace)

	remotedostring(cmd)
end

mapPath = "D:\\Warcraft III\\Mapping\\postproc\\output.w3x"wc3path = "D:\\Warcraft III"
runFunc = function(f, ...)
	local t = {...}

	for i = 1, #t, 1 do
		local v = t[i]

		if (type(v) == 'string') then
			t[i] = string.format('%q', v)
		else
			t[i] = tostring(v)
		end
	end

	local s = table.concat(t, ',') or ''

	local cmd = string.format('%s(%s)', f, s)

	local function pack(...)
		return {...}
	end
	
	_ret = {}
	
	local success, msg = remotedostring(cmd)

	local t = _ret

	_ret = nil

	if not success then
		error(msg)
	end

	return unpack(t)
end

runTool = function(name, args)
	args = args or {}

	return runFunc('runToolAdapter', name, unpack(args))
end

runToolEx = function(name, args)
	args = args or {}

	return runFunc('runToolExAdapter', name, unpack(args))
end

createTmpFile = function(s)
	return runFunc('createTmpFileAdapter', s)
end

log = function(...)
	return runFunc('logAdapter', ...)
end

unwrap = function(path)
	return runFunc('unwrapAdapter', path)
end

wrap = function(path)
	return runFunc('wrapAdapter', path)
end

xpcall(xpfunc, errorHandler)