local params = {...}

local mapPath = params[1]
local outputPath = params[2]
local instructionFilePath = params[3]
local wc3path = params[4]
local moreConfigPath = params[5]
local logPath = params[6]

assert(mapPath, 'no mapPath')
assert(outputPath, 'no outputPath')

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

local function requireEx2(path)
	assert(path, 'no path')

	path = path:gsub('/', '\\')

	local dir, name = path:match("(.*\\)(.*)")

	if (dir ~= nil) then
		local add = dir..'?\\init'

		addPackagePath(add)

		local add = path..'\\?'

		addPackagePath(add)
	end

	require(name)
end

local function requireEx(dir, name)
	assert(dir, 'no dir')
	assert(name, 'no name')

	requireEx2(dir..'\\'..name)
end

requireEx(config.assignments['waterlua'], 'waterlua')
requireEx(config.assignments['wc3libs'], 'wc3binary')

local toolsLookupPath = config.assignments['toolsLookup']

if (toolsLookupPath ~= nil) then
	toolsLookupPath = toolsLookupPath:gsub('/', '\\')

	if not toolsLookupPath:match('\\$') then
		toolsLookupPath = toolsLookupPath..'\\'
	end

	if not io.isAbsPath(toolsLookupPath) then
		toolsLookupPath = io.local_dir()..toolsLookupPath
	end
end

local defLogPath = io.local_dir()..'log.txt'

if (logPath == nil) then
	logPath = defLogPath

	os.remove(defLogPath)
else
	os.remove(logPath)
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

		local t = line:split(',')

		local name = t[1]
		local path = t[2]

		if (name ~= nil) and (name ~= '') then
			name = name:gsub("\"", "")
			if (path ~= nil) then
				path = path:gsub("\"", "")
			end

			local exttool = {}

			exttool.name = name
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
		instructionLines[#instructionLines + 1] = line
	end
else
	for line in instructionFile:lines() do
		instructionLines[#instructionLines + 1] = line
	end
end

local lineNum = 0

for i, line in pairs(instructionLines) do
	lineNum = lineNum + 1

	postprocLog:write('line ', lineNum, ': ', line, '\n')

	local sear = '^%s*//!%s+post%s+([%w%d_]*)'

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

	local sear = '^%s*//!%s+postblock%s+([%w%d_]*)'

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
	elseif line:match('^%s*//! i ') then
		local pos, posEnd = line:find('^%s*//! i ')

		if (posEnd ~= nil) then
			local lineTrunc = line:sub(posEnd + 1)

			if (lineTrunc ~= nil) then
				if (curExtCallBlock ~= nil) then
					curExtCallBlock.lines[#curExtCallBlock.lines + 1] = lineTrunc
				end
			end
		end
	else
		if line:match('^%s*//! endpostblock') then
			curExtCallBlock = nil
		end
	end

	if line:find('^%s*//!%s+noJasshelper') then
		postprocLog:write('found noJasshelper ', ' at line ', lineNum, '\n')

		noJasshelper = true
	end
end

instructionFile:close()

local throwError = false

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

	if (tool ~= nil) then
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

		local hasError = false
		local errorMsg = nil
		local resLevel = nil

		if (lfs.attributes(tool.path) == nil) then
			hasError = true
			errorMsg = 'tool '..tostring(extCall.name)..' not found, tried:\n'..table.concat(tryTable, '\n')
		end

		if not hasError then
			for i = 1, #extCall.args, 1 do
				local arg = extCall.args[i]

				if (arg == '$MAP$') then
					arg = mapPath
				end
				if (arg == '$FILENAME$') then
					arg = tmpFileName
				end

				extCall.args[i] = arg
			end

			if (getFileExtension(tool.path) == 'lua') then
				local func = loadfile(tool.path)

				local t = {}

				t[#t + 1] = tool.path

				for i = 1, #extCall.args, 1 do
					t[#t + 1] = tostring(extCall.args[i])
				end

				print('call', table.concat(t, ' '))
				postprocLog:write('call: ', table.concat(t, ' '), '\n')

				if (func ~= nil) then
					local luaResVal

					luaResVal, errorMsg = xpcall(function() return func(unpack(extCall.args)) end, function(msg) postprocLog:write(msg, '\n'); postprocLog:write(debug.traceback('', 2):sub(2), '\n') end)

					hasError = hasError or not luaResVal
				else
					hasError = true
					errorMsg = 'tool not found on '..tool.path
				end
			else
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

				local cmd = table.concat(t, ' ')

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

		if hasError then
			postprocLog:write('error: an error occurred', '\n')

			if (resLevel ~= nil) then
				postprocLog:write('error: tool returned error level '..tostring(resLevel), '\n')
			end

			if (errorMsg ~= nil) then
				postprocLog:write('errorMsg: '..tostring(errorMsg), '\n')
			end

			throwError = true
		end
	else
		postprocLog:write('tool ' .. extCall.name .. ' not defined')
	end
end

postprocLog:close()

if throwError then
	error('postproc: there were errors, see '..logPath..' for details')
end

return true, (not noJasshelper)