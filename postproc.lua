local params = {...}

local mapPath = params[1]
local outputPath = params[2]
local instructionFilePath = params[3]
local wc3path = params[4]
local moreConfigPath = params[5]
local logPath = params[6]

assert(mapPath, 'no mapPath')
assert(outputPath, 'no outputPath')

assert(mapPath ~= outputPath, 'input and output path are equal')

local function script_path()
	local str = debug.getinfo(2, "S").source:sub(2)

	str = str:gsub('/', '\\')

	local dir = str:match("(.*\\)")

	if (dir == nil) then
		return ''
	end

	return dir
end

local function createConfig()
	local this = {}

	this.assignments = {}
	this.sections = {}

	function this:readFromFile(path, ignoreNotFound)
		assert(path, 'configParser: no path passed')

		local f = io.open(path, 'r')

		if not ignoreNotFound then
			assert(f, 'configParser: cannot open file '..tostring(path))
		end

		local curSection = nil

		for line in f:lines() do
			line = line:gsub('\\\\', '\\')

			local sectionName = line:match('%['..'([%w%d%p_]*)'..'%]')

			if (sectionName ~= nil) then
				curSection = this.sections[sectionName]

				if (curSection == nil) then
					curSection = {}

					this.sections[sectionName] = curSection

					curSection.assignments = {}
					curSection.lines = {}
				end
			elseif (curSection ~= nil) then
				curSection.lines[#curSection.lines + 1] = line
			end

			local pos, posEnd = line:find('=')

			if pos then
				local name = line:sub(1, pos - 1)
				local val = line:sub(posEnd + 1, line:len())

				if ((type(val) == 'string')) then
					val = val:match("\"(.*)\"")
				end

				if (curSection ~= nil) then
					curSection.assignments[name] = val
				else
					this.assignments[name] = val
				end
			end
		end

		f:close()
	end

	return this
end

local config = createConfig()

local configPath = script_path()..'config.conf'

config:readFromFile(configPath)

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

local function requireDir(path)
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

	path = path:match('(.*\\)')

	if not io.isAbsPath(path) then
		path = io.curDir()..path
	end

	return path
end

requireDir(io.toAbsPath(config.assignments['waterlua'], io.local_dir()))
requireDir(io.toAbsPath(config.assignments['wc3libs'], io.local_dir()))

local toolEnvTemplate = copyTable(_G)

local toolsLookupPath = config.assignments['toolsLookup']

if (toolsLookupPath ~= nil) then
	toolsLookupPath = toolsLookupPath:gsub('/', '\\')

	if not toolsLookupPath:match('\\$') then
		toolsLookupPath = toolsLookupPath..'\\'
	end

	toolsLookupPath = io.toAbsPath(toolsLookupPath, io.local_dir())
end

local defLogPath = io.local_dir()..'log.txt'

if (logPath == nil) then
	logPath = defLogPath

	removeFile(defLogPath)
else
	removeFile(logPath)
end

local postprocLog = io.open(logPath, 'w+')

local noJasshelper = false

mapPath = io.toAbsPath(mapPath)

if not io.isAbsPath(outputPath) then
	outputPath = io.curDir()..outputPath
end

copyFile(mapPath, outputPath, true)

mapPath = outputPath

if (moreConfigPath ~= nil) then
	config:readFromFile(moreConfigPath, true)
end

local exttools = {}
local exttoolsByName = {}

local externalToolsSection = config.sections['externaltools']

if (externalToolsSection ~= nil) then
	for i = 1, #externalToolsSection.lines, 1 do
		local line = externalToolsSection.lines[i]

		local name, vals = line:match('([%w%d%p_]+)=([%w%d%p_]+)')

		if (name ~= nil) and (name ~= '') then
			vals = vals:split(';')

			local path = vals[1]
			local flags = vals[2]

			name = name:gsub("\"", "")
			if (path ~= nil) then
				path = path:gsub("\"", "")
			end

			if (flags ~= nil) then
				flags = flags:split(',')
			else
				flags = {}
			end

			local exttool = {}

			exttool.name = name
			exttool.flags = flags
			exttool.path = path

			exttools[#exttools + 1] = exttool
			exttoolsByName[name] = exttool
		end
	end
end

local extCalls = {}
local curExtCallBlock = nil

if (instructionFilePath == nil) then
	instructionFilePath = io.local_dir()..'war3map.wct'

	removeFile(instructionFilePath)

	mpqExtract(mapPath, 'war3map.wct', instructionFilePath)

	postprocLog:write('reading from internal .wct', '\n')
end

local instructionFile = io.open(instructionFilePath, 'r')

assert(instructionFile, 'cannot open '..tostring(instructionFilePath))

local instructionLines = {}

if (getFileExtension(instructionFilePath) == 'wct') then
	local root = wc3binaryFile.create()

	root:readFromFile(instructionFilePath, wctMaskFunc)

	local headTrig = root:getSub('headTrig')

	local text = headTrig:getVal('text')

	for i, line in pairs(text:split('\n')) do
		line = line:match('^%s*//!%s+i%s+(.*)') or line:match('^%s*//!%s+(.*)')

		if (line ~= nil) then
			instructionLines[#instructionLines + 1] = line
		end
	end
else
	for line in instructionFile:lines() do
		instructionLines[#instructionLines + 1] = line
	end
end

local lineNum = 0
local vars = {}

for i, line in pairs(instructionLines) do
	lineNum = lineNum + 1

	postprocLog:write('line ', lineNum, ': ', line, '\n')

	local sear = 'post%s+([%w%d_]*)'

	local name = line:match(sear)

	if ((name ~= nil) and (name ~= '')) then
		postprocLog:write('found ', name, ' at line ', lineNum, '\n')

		local pos, posEnd = line:find(sear)

		line = line:sub(posEnd + 1)

		local extCall = {}

		extCall.name = name
		extCall.args = {}

		extCalls[#extCalls + 1] = extCall

		while (line:len() > 0) do
			local pos, posEnd = line:find('[^%s]')

			if (pos == nil) then
				line = ""
			else
				line = line:sub(pos)

				local arg = nil

				if (line:sub(1, 1) == "\"") then
					line = line:sub(2)

					local pos, posEnd = line:find("\"")

					if (pos == nil) then
						pos = line:len() + 1
					end

					arg = line:sub(1, pos - 1)

					if (posEnd == nil) then
						line = ""
					else
						line = line:sub(posEnd + 1)
					end
				else
					local pos, posEnd = line:find('%s')

					if (pos == nil) then
						pos = line:len() + 1
					end

					arg = line:sub(1, pos - 1)

					if (posEnd == nil) then
						line = ""
					else
						line = line:sub(posEnd + 1)
					end
				end

				if (arg ~= nil) then
					extCall.args[#extCall.args + 1] = arg
				end
			end
		end
	end

	local sear = 'postblock%s+([%w%d_]*)'

	local name = line:match(sear)

	if ((name ~= nil) and (name ~= '')) then
		postprocLog:write('found block ', name, ' at line ', lineNum, '\n')

		local pos, posEnd = line:find(sear)

		line = line:sub(posEnd + 1)

		local extCall = {}

		extCall.name = name
		extCall.args = {}

		extCalls[#extCalls + 1] = extCall

		while (line:len() > 0) do
			local pos, posEnd = line:find('[^%s]')

			if (pos == nil) then
				line = ""
			else
				line = line:sub(pos)

				local arg = nil

				if (line:sub(1, 1) == "\"") then
					line = line:sub(2)

					local pos, posEnd = line:find("\"")

					if (pos == nil) then
						pos = line:len() + 1
					end

					arg = line:sub(1, pos - 1)

					if (posEnd == nil) then
						line = ""
					else
						line = line:sub(posEnd + 1)
					end
				else
					local pos, posEnd = line:find('%s')

					if (pos == nil) then
						pos = line:len() + 1
					end

					arg = line:sub(1, pos - 1)

					if (posEnd == nil) then
						line = ""
					else
						line = line:sub(posEnd + 1)
					end
				end

				if (arg ~= nil) then
					extCall.args[#extCall.args + 1] = arg
				end
			end
		end

		curExtCallBlock = extCall

		extCall.lines = {}
	elseif line:match('endpostblock') then
		curExtCallBlock = nil
	else
		if (curExtCallBlock ~= nil) then
			local lineTrunc = line

			if (lineTrunc:find('%s') == 1) then
				lineTrunc = lineTrunc:sub(2)
			end

			curExtCallBlock.lines[#curExtCallBlock.lines + 1] = lineTrunc
		end
	end

	if line:find('noJasshelper') then
		postprocLog:write('found noJasshelper ', ' at line ', lineNum, '\n')

		noJasshelper = true
	end

	local name, val = line:match('%$([%w%d%p_]+)%$ = ([%w%d%p_]+)')

	if (name ~= nil) then
		postprocLog:write('set '..tostring(name)..' to '..tostring(val), '\n')

		vars[name] = val
	end
end

instructionFile:close()

vars['MAP'] = mapPath

local throwError = false
local throwErrorMsg = nil

for i = 1, #extCalls, 1 do
	local extCall = extCalls[i]

	local tmpFile = nil
	local tmpFileName

	if (wc3path == nil) then
		tmpFileName = io.local_dir()..'tmpFile.tmp'
	else
		tmpFileName = wc3path..'\\postproc.tmp'
	end

	local tool = exttoolsByName[extCall.name]

	local hasError = false
	local errorMsg = nil
	local resLevel = nil

	if (tool ~= nil) then
		vars['FILENAME'] = tmpFileName

		local tryTable = {}

		tryTable[#tryTable + 1] = tool.path

		if not io.isAbsPath(tool.path) then
			if (toolsLookupPath ~= nil) then
				tryTable[#tryTable + 1] = toolsLookupPath..tool.path
			end
		end

		tool.path = tryTable[1]

		local i = 2

		while ((lfs.attributes(tool.path) == nil) and (i <= #tryTable)) do
			tool.path = tryTable[i]

			i = i + 1
		end

		if (lfs.attributes(tool.path) == nil) then
			hasError = true
			errorMsg = 'tool '..tostring(extCall.name)..' not found, tried:\n'..table.concat(tryTable, '\n')
		end

		local cmd = nil

		if not hasError then
			for i = 1, #extCall.args, 1 do
				local arg = extCall.args[i]

				local varName = arg:match('%$(.*)%$')

				if (varName ~= nil) then
					local varVal = vars[varName]

					if varVal then
						arg = varVal
					end
				end

				extCall.args[i] = arg
			end

			do
				local t = {}

				t[#t + 1] = tostring(tool.path):gsub("\\\\", "\\")

				if (extCall.lines ~= nil) then
					tmpFile = io.open(tmpFileName, 'w+')

					tmpFile:write(table.concat(extCall.lines, '\n'))
				end

				for j = 1, #extCall.args, 1 do
					local arg = extCall.args[j]

					if (tonumber(arg) == nil) then
						if (arg:sub(1, 1) ~= "-") then
							if (arg:sub(arg:len(), arg:len()) == "\\") then
								arg = arg .. "\\"
							end

							arg = "\"" .. arg .. "\""
						end
					end

					t[#t + 1] = arg
				end

				if (tmpFile ~= nil) then
					tmpFile:close()
				end

				cmd = table.concat(t, ' ')
			end

			if (getFileExtension(tool.path) == 'lua') then
				local func = loadfile(tool.path)

				print('luacall', cmd)
				postprocLog:write('luacall: ', cmd, '\n')

				if (func ~= nil) then
					local luaResVal = nil

					local function regError(msg, trace)
						errorMsg = msg
						hasError = true
						postprocLog:write(msg, '\n')
						postprocLog:write(trace, '\n')
					end

					local xpfunc = function()
						return func(unpack(extCall.args))
					end

					local errorHandler = function(msg)
						local trace = debug.traceback('', 2):sub(2)

						regError(msg, trace)
					end

					--luaResVal = xpcall(xpfunc, errorHandler)

					--hasError = hasError or not luaResVal

					local function toolError(msg, trace)
						regError(msg, trace)
					end

					--setfenv(func, copyTable(toolEnvTemplate))

					local toolEnv = {}

					toolEnv.toolError = toolError

					local function runFile(path)
						local s = [[--generated tool caller (]]..tool.name..[[)
package.path = ]]..string.format('%q', package.path)..[[
package.cpath = ]]..string.format('%q', package.cpath)..[[

local func = loadfile(]]..string.format('%q', tool.path)..[[)

local xpfunc = function()
	local args = ]]..tableToLua(extCall.args)..[[

	return func(unpack(args))
end

local errorHandler = function(msg)
	local trace = debug.traceback('', 2):sub(2)

	local cmd = string.format('toolError(%q, %q)', msg, trace)

	remotedostring(cmd)
end

xpcall(xpfunc, errorHandler)]]

						--local f = io.open(io.local_dir()..'sandboxer.lua', 'w+')

						--f:write(s)

						--f:close()

						local sub = rings.new(toolEnv)

						local ringRes, ringErrorMsg = sub:dostring(s)

						if not ringRes then
							hasError = true
							errorMsg = 'sandboxer: '..tostring(ringErrorMsg)
						end
					end

					runFile(tool.path)
				else
					hasError = true
					errorMsg = 'tool not found on '..tool.path
				end
			else
				print('call', cmd)
				postprocLog:write('call: ', cmd, '\n')

				if (wehack ~= nil) then
					resLevel = wehack.runprocess2(cmd)
				else
					resLevel = runProg(tool.path, extCall.args)
				end

				hasError = hasError or (resLevel ~= 0)
			end
		end
	else
		hasError = true
		errorMsg = 'tool ' .. extCall.name .. ' not defined'

		print(errorMsg)
		postprocLog:write(errorMsg)
	end

	if hasError then
		postprocLog:write('error: an error occurred', '\n')

		if (resLevel ~= nil) then
			postprocLog:write('error: tool returned error level '..tostring(resLevel), '\n')
		end

		if (errorMsg ~= nil) then
			postprocLog:write('errorMsg: '..tostring(errorMsg), '\n')
		end

		if ((tool == nil) or not tableContains(tool.flags, 'noErrorPrompt')) then
			throwError = true
			throwErrorMsg = errorMsg
			throwErrorCall = cmd
		end

		break
	end
end

postprocLog:close()

if throwError then
	local t = {}

	t[#t + 1] = 'postproc: there were errors, see '..logPath..' for details'

	if (throwErrorCall ~= nil) then
		t[#t + 1] = ''

		t[#t + 1] = 'call:\n'..throwErrorCall
	end

	if (throwErrorMsg ~= nil) then
		t[#t + 1] = ''

		t[#t + 1] = 'errorMsg:\n'..throwErrorMsg
	end

	error(table.concat(t, '\n'), 0)
end

return true, (not noJasshelper)