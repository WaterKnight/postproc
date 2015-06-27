local function script_path()
	local str = debug.getinfo(2, "S").source:sub(2)

	str = str:gsub('/', '\\')

	local dir = str:match("(.*\\)")

	if (dir == nil) then
		return ''
	end

	return dir
end

package.path = package.path..';'..script_path()..[[?.lua]]
package.cpath = package.cpath..';'..script_path()..[[?.dll]]

require 'rings'

local function reduceFolder(path)
	assert(path, 'no path')

	path = path:sub(1, path:len() - 1)

	local dir = path:match("(.*\\)")

	if (dir == nil) then
		return ''
	end

	return dir
end

function tableToLua(t)
	local res = {}

	for k, v in pairs(t) do
		if (type(v) == 'table') then
			v = tableToLua(v)
		else
			if (type(v) == 'string') then
				v = string.format('%q', v)
			else
				v = tostring(v)
			end
		end

		if (type(k) == 'number') then
			res[#res + 1] = v
		else
			res[#res + 1] = k..'='..tostring(v)
		end
	end

	return '{'..table.concat(res, ', ')..'}'
end

local function toLuaSingle(val)
	if (val == nil) then
		return 'nil'
	end

	if (type(val) == 'boolean') then
		if val then
			return 'true'
		end

		return 'false'
	end

	if (type(val) == 'number') then
		return val
	end

	if (type(val) == 'string') then
		return string.format('%q', val)
	end

	if (type(val) == 'table') then
		return tableToLua(val)
	end

end

local function toLua(...)
	local t = {...}

	if (#t < 1) then
		return
	end

	for i = 1, #t, 1 do
		t[i] = toLuaSingle(t[i])
	end

	return table.concat(t, ', ')
end

function jngp_createShell(path)
	assert(path, 'no path')

	local shell = {}

	function shell:exec(...)
		local sub = rings.new()

		local function doString(s)
			local function pack(...)
				return arg
			end

			local t = pack(sub:dostring(s))

			local ok = t[1]

			if not ok then
				local errorMsg = t[2]
				local errorTrace = t[3]

				error(errorMsg)
			end

			return select(2, t)
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

			while (path:find('..\\') == 1) do
				result = result:reduceFolder()

				path = path:sub(4)
			end

			result = result..path

			return result
		end

		io.toAbsPath = function(path, basePath)
			return toAbsPath(path, basePath)
		end

		require 'lfs'

		io.curDir = function()
			return toFolderPath(lfs.currentdir())
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

		local getConfigsPath = reduceFolder(script_path())..'postproc_getconfigs.lua'

		local config = dofile(getConfigsPath)

		local waterluaPath = config.assignments['waterlua']
		local wc3libsPath = config.assignments['wc3libs']

		assert(waterluaPath, 'no waterlua path found')
		assert(wc3libsPath, 'no wc3libs path found')

		waterluaPath = io.toAbsPath(waterluaPath, getFolder(getConfigsPath))
		wc3libsPath = io.toAbsPath(wc3libsPath, getFolder(getConfigsPath))

		local s = [[
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

			local function addPackageDir(path)
				assert(path, 'no path')

				path = path:gsub('/', '\\')

				local dir, name = path:match("(.*\\)(.*)")

				if (dir ~= nil) then
					local add = dir..'?\\init'

					addPackagePath(add)

					local add = path..'\\?'

					addPackagePath(add)
				end
			end

			addPackageDir(]]..toLua(waterluaPath)..[[)
			addPackageDir(]]..toLua(wc3libsPath)..[[)
		]]

		doString(s)

		local s = [[
			local f = loadfile(]]..toLua(path)..[[)

			assert(f, 'cannot open '..tostring(]]..toLua(path)..[[))

			f(]]..toLua(...)..[[)
		]]

		--error(tostring(t[1]['postprocDir'])..';'..tostring(t[1]['mapPath']))
		--error(s)

		return doString(s)
	end

	return shell
end

