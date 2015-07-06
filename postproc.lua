local params = {...}

local mapPath = params[1]
local outputPath = params[2]
local instructionFilePath = params[3]
local wc3path = params[4]
local moreConfigPath = params[5]
local logPath = params[6]
local useConsoleLog = params[7]

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

package.path = script_path()..'?.lua'..';'..package.path

require 'orient'

local config = dofile(script_path()..'postproc_getconfigs.lua')

addPackagePath(script_path()..'?')

local waterluaPath = config.assignments['waterlua']
local wc3libsPath = config.assignments['wc3libs']

assert(waterluaPath, 'no waterlua path found')
assert(wc3libsPath, 'no wc3libs path found')

requireDir(io.toAbsPath(waterluaPath, io.local_dir()))
requireDir(io.toAbsPath(wc3libsPath, io.local_dir()))

local function updateInstructions()
	local postprocDir = io.local_dir()

	--local mapRepo = postprocDir..[[temp\instructions\]]..getFileName(mapPath, true)..[[\]]
	local mapRepo = mapPath..[[_postproc\]]

	if not io.pathExists(mapRepo) then
		return nil
	end

	local indexPath = mapRepo..[[_index.txt]]
	local currentPath = mapRepo..[[_current.txt]]

	local t = getFiles(mapRepo, '*.lua')

	local indexFile = io.open(indexPath, 'w+')

	assert(indexFile, 'cannot open '..tostring(indexPath))

	for k, v in pairs(t) do
		--v = v:match('([^\\]*).lua')
		v = getFileName(v)

		if (v ~= nil) then
			indexFile:write(v, '\n')
		end
	end

	indexFile:close()

	local curInstructionPath
	
	if io.pathExists(currentPath) then
		local curFile = io.open(currentPath, 'r')

		curInstructionPath = curFile:read('*a'):match('([^%s]+)')

		if (curInstructionPath ~= nil) then
			if not curInstructionPath:match('%[.*%]') then
				curInstructionPath = mapRepo..curInstructionPath
			end
		end

		curFile:close()
	else
		curInstructionPath = nil
	end

	require 'portLib'

	local port = createMpqPort()

	port:addImport(indexPath, [[postproc\instructions\_index.txt]])
	port:addImport(currentPath, [[postproc\instructions\_current.txt]])

	for k, v in pairs(t) do
		port:addImport(v, [[postproc\instructions\]]..v:match('([^\\]*)$'))
	end

	port:commit(mapPath)

	return curInstructionPath
end

local lastInstructionFilePath = updateInstructions()

local toolEnvTemplate = copyTable(_G)

local toolsLookupPaths = config.assignments['toolsLookup']

if (toolsLookupPaths ~= nil) then
	toolsLookupPaths = totable(toolsLookupPaths)

	for i, path in pairs(toolsLookupPaths) do
		path = path:gsub('/', '\\')

		if not path:match('\\$') then
			path = path..'\\'
		end

		path = io.toAbsPath(path, io.local_dir())

		toolsLookupPaths[i] = path
	end
else
	toolsLookupPaths = {}
end

local defLogPath = io.local_dir()..'log.txt'

if (logPath == nil) then
	logPath = defLogPath

	removeFile(defLogPath)
else
	removeFile(logPath)
end

local postprocLog = io.open(logPath, 'w+')

local logPipe

if (useConsoleLog == true) then
	local logPipePath = io.local_dir()..'pipe.bat'
	
	local f = io.open(logPipePath, 'w+')

	assert('could not open '..logPipePath)
	
	f:write(string.format([[echo off
	title postproc -  %s
	mode con:lines=550

	find /v "" > con]], os.date('postproc log - %x %X - '..mapPath, os.time())))

	f:close()

	logPipe = io.popen(string.format([[call %q > con]], logPipePath), 'w')
end

local function log(s)
	--print(s)
	if (logPipe ~= nil) then
		logPipe:write(s, '\n')
		logPipe:flush()
	end
	postprocLog:write(s, '\n')
end

log(os.date('postproc log - %x %X - '..mapPath, os.time()))

local noDefaultTools = false

mapPath = io.toAbsPath(mapPath)

if not io.isAbsPath(outputPath) then
	outputPath = io.curDir()..outputPath
end

copyFile(mapPath, outputPath, true)

local lastOutputPathFilePath = io.local_dir()..'lastOutputPath.txt'

local lastOutputPathFile = io.open(lastOutputPathFilePath, 'w+')

assert(lastOutputPathFile, 'cannot open '..lastOutputPathFilePath)

lastOutputPathFile:write(outputPath)

lastOutputPathFile:close()

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

local toolsSlk = createSlk()

toolsSlk:readFromFile(io.local_dir()..'configTools.slk')

for name, objData in pairs(toolsSlk.objs) do
	local exttool = {}

	exttool.name = name
	exttool.flags = (objData.vals['flags'] or ''):split(';')
	exttool.path = objData.vals['path']
	exttool.workDir = objData.vals['working directory']

	exttools[#exttools + 1] = exttool
	exttoolsByName[name] = exttool
end

local extCalls = {}
local curExtCallBlock = nil

if (instructionFilePath == nil) then
	if (lastInstructionFilePath ~= nil) then
		instructionFilePath = lastInstructionFilePath
	else
		instructionFilePath = '[internal]'
	end
end

if (instructionFilePath == '[internal]') then
	instructionFilePath = io.local_dir()..'war3map.wct'

	removeFile(instructionFilePath)

	mpqExtract(mapPath, 'war3map.wct', instructionFilePath)

	log('reading from internal .wct')
end

local throwError = false
local throwErrorMsg = nil

local function runToolEx(name, args)
	assert(name, 'no tool')
	
	local tool = exttoolsByName[name]
	
	assert(tool, 'unknown tool ('..tostring(name)..')')

	local tryTable = {}

	tryTable[#tryTable + 1] = io.toAbsPath(tool.path, io.curDir())

	if not io.isAbsPath(tool.path) then
		for i, path in pairs(toolsLookupPaths) do
			tryTable[#tryTable + 1] = path..tool.path
		end
	end

	tool.path = tryTable[1]

	local i = 2

	while ((lfs.attributes(tool.path) == nil) and (i <= #tryTable)) do
		tool.path = tryTable[i]

		i = i + 1
	end

	if (lfs.attributes(tool.path) == nil) then
		return false, 'tool '..tostring(name)..' not found, tried:\n'..table.concat(tryTable, '\n')
	end

	local cmd = nil

	args = args or {}

	do
		local t = {}

		t[#t + 1] = tostring(tool.path):gsub("\\\\", "\\")

		for j = 1, #args, 1 do
			local arg = args[j]

			if (tonumber(arg) == nil) then
				arg = tostring(arg)

				if (arg:sub(1, 1) ~= "-") then
					if (arg:sub(arg:len(), arg:len()) == "\\") then
						arg = arg .. "\\"
					end

					arg = "\"" .. arg .. "\""
				end
			end

			t[#t + 1] = arg
		end

		cmd = table.concat(t, ' ')
	end

	if (getFileExtension(tool.path) == 'lua') then
		log('luacall: ', cmd)

		local func = loadfile(tool.path)
		
		if (func == nil) then
			local found, notFoundMsg = syntaxCheck(tool.path)

			if not found then
				return false, notFoundMsg
			end

			return false, 'tool not found on '..tool.path
		end

		local function spanSandbox(path)
			local s = [[--generated tool caller (]]..tool.name..[[)
package.path = ]]..string.format('%q', package.path)..[[
package.cpath = ]]..string.format('%q', package.cpath)..[[

local func = loadfile(]]..string.format('%q', tool.path)..[[)

local xpfunc = function()
	local args = ]]..tableToLua(args)..[[

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

			local hasError = false
			local errorMsg

			local function regError(msg, trace)
				errorMsg = msg..'\n'..trace
				hasError = true

				log(msg)
				log(trace)
			end

			local function toolError(msg, trace)
				regError(msg, trace)
			end

			local toolEnv = {toolError = toolError}

			local sub = rings.new(toolEnv)

			local ringRes, ringErrorMsg = sub:dostring(s)

			if hasError then
				return false, errorMsg
			end

			if not ringRes then
				return false, 'sandboxer: '..tostring(ringErrorMsg)
			end

			return true
		end

		return spanSandbox(tool.path)
	end

	log('call: ', cmd)

	local resLevel

	if (wehack ~= nil) then
		resLevel = wehack.runprocess2(cmd)
	else
		local workDir = tool.workDir

		if (workDir ~= nil) then
			workDir = io.toAbsPath(workDir, getFolder(tool.path))
		end

		resLevel = osLib.runProg(nil, tool.path, args, nil, nil, workDir)

		if (resLevel == true) then
			resLevel = 0
		else
			resLevel = -1
		end
	end

	return (resLevel == 0)
end

local function runTool(name, args)
	assert(name, 'no tool')
	
	local tool = exttoolsByName[name]
	
	assert(tool, 'unknown tool ('..tostring(name)..')')

	local success, errorMsg = runToolEx(name, args)

	if not success then
		log('error: an error occurred')

		if (resLevel ~= nil) then
			log('error: tool returned error level '..tostring(resLevel))
		end

		if (errorMsg ~= nil) then
			log('errorMsg: '..tostring(errorMsg))
		end

		if ((tool == nil) or (resLevel == nil) or not tableContains(tool.flags, 'noErrorPrompt')) then
			throwError = true

			if (throwErrorMsg == nil) then
				throwErrorMsg = ''
			end
			throwErrorMsg = throwErrorMsg..'\n'..errorMsg
			
			local cmdArgs = {}
			
			for i = 1, #args, 1 do
				cmdArgs[i] = tostring(args[i])
			end
			
			local cmd = string.format('%s(%s)', name, table.concat(cmdArgs, ','))
			
			if (throwErrorCall == nil) then
				throwErrorCall = ''
			end
			throwErrorCall = throwErrorCall..'\n'..cmd
		end
	end

	return throwError
end

local function createTmpFile(s)
	local tmpFileName

	if (wc3path == nil) then
		tmpFileName = io.local_dir()..'tmpFile.tmp'
	else
		tmpFileName = wc3path..'\\postproc.tmp'
	end

	local f = io.open(tmpFileName, 'w+')

	if (s ~= nil) then
		f:write(s)
	end

	f:close()

	return tmpFileName
end

local function unwrap(path)
	path = path or io.local_dir()..[[temp\unwrapped\]]

	flushDir(path)

	mpqExtractAll(mapPath, path)

	return path
end

local function wrap(path)
	path = path or io.local_dir()..[[temp\unwrapped\]]

	mpqImportAll(mapPath, path)

	return path
end

if (getFileExtension(instructionFilePath) == 'lua') then
	local success, errorMsg = syntaxCheck(instructionFilePath)

	if not success then
		throwError = true
		throwErrorMsg = 'syntax error in instruction file '..instructionFilePath..':\n'..errorMsg
	else
		local function spanSandbox(path)
			local sub

			local function pack(...)
				return {...}
			end

			local function runFuncAdapter(f, ...)
				local t = pack(f(...))

				if (#t > 0) then
					local t2 = {}

					for i = 1, #t, 1 do
						if (type(t[i]) == 'string') then
							t2[#t2 + 1] = string.format([[_ret[%s] = %q]], i, tostring(t[i]))
						else
							t2[#t2 + 1] = string.format([[_ret[%s] = %s]], i, tostring(t[i]))
						end
					end

					local s = table.concat(t2, '\n')
					
					local suc, msg = sub:dostring(s)
				end
			end

			local function runToolAdapter(name, ...)
				runFuncAdapter(runTool, name, {...})
			end

			local function runToolExAdapter(name, ...)
				runFuncAdapter(runToolEx, name, {...})
			end

			local function createTmpFileAdapter(...)
				runFuncAdapter(createTmpFile, ...)
			end

			local function logAdapter(...)
				runFuncAdapter(log, ...)
			end

			local function unwrapAdapter(...)
				runFuncAdapter(unwrap, ...)
			end

			local function wrapAdapter(...)
				runFuncAdapter(wrap, ...)
			end

			local s = [[--generated instruction file caller (]]..instructionFilePath..[[)
package.path = ]]..string.format('%q', package.path)..[[
package.cpath = ]]..string.format('%q', package.cpath)..[[

local func = loadfile(]]..string.format('%q', instructionFilePath)..[[)

local xpfunc = function()
	local args = {}

	return func(unpack(args))
end

local errorHandler = function(msg)
	local trace = debug.traceback('', 2):sub(2)

	local cmd = string.format('toolError(%q, %q)', msg, trace)

	remotedostring(cmd)
end

mapPath = ]]..string.format('%q', mapPath)..[[
wc3path = ]]..string.format('%q', wc3path)..[[

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

log = function(s)
	return runFunc('logAdapter', s)
end

unwrap = function(path)
	return runFunc('unwrapAdapter', path)
end

wrap = function(path)
	return runFunc('wrapAdapter', path)
end

xpcall(xpfunc, errorHandler)]]

			local f = io.open(io.local_dir()..'sandboxer.lua', 'w+')

			f:write(s)

			f:close()

			local hasError = false
			local errorMsg

			local function regError(msg, trace)
				errorMsg = msg..'\n'..trace
				hasError = true

				log(msg)
				log(trace)
			end

			local function toolError(msg, trace)
				regError(msg, trace)
			end

			local toolEnv = {toolError = toolError, runToolAdapter = runToolAdapter, runToolExAdapter = runToolExAdapter, createTmpFileAdapter = createTmpFileAdapter, logAdapter = logAdapter, unwrapAdapter = unwrapAdapter, wrapAdapter = wrapAdapter}

			sub = rings.new(toolEnv)

			local ringRes, ringErrorMsg = sub:dostring(s)

			if hasError then
				return false, errorMsg
			end

			if not ringRes then
				return false, 'sandboxer: '..tostring(ringErrorMsg)
			end

			return true
		end
		
		local success, errorMsg = spanSandbox(instructionFilePath)
		
		if not success then
			throwError = true
			throwErrorMsg = errorMsg
		end
	end
else
	local instructionLines = {}

	if (getFileExtension(instructionFilePath) == 'wct') then
		local root = wc3binaryFile.create()

		root:readFromFile(instructionFilePath, wctMaskFunc)

		local headTrig = root:getSub('headTrig')

		local text = headTrig:getVal('text', true)

		if (text ~= nil) then
			for i, line in pairs(text:split('\n')) do
				line = line:match('^%s*//!%s+i%s+(.*)') or line:match('^%s*//!%s+(.*)')

				if (line ~= nil) then
					instructionLines[#instructionLines + 1] = line
				end
			end
		end
	else
		local instructionFile = io.open(instructionFilePath, 'r')

		assert(instructionFile, 'cannot open '..tostring(instructionFilePath))

		for line in instructionFile:lines() do
			instructionLines[#instructionLines + 1] = line
		end
		
		instructionFile:close()
	end

	local lineNum = 0
	local vars = {}

	for i, line in pairs(instructionLines) do
		lineNum = lineNum + 1

		log('line ', lineNum, ': ', line)

		local sear = 'post%s+([%w%d_]*)'

		local name = line:match(sear)

		if ((name ~= nil) and (name ~= '')) then
			log('found ', name, ' at line ', lineNum)

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
			log('found block ', name, ' at line ', lineNum)

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

		if line:find('noDefaultTools') then
			log('found noDefaultTools ', ' at line ', lineNum)

			noDefaultTools = true
		end

		local name, val = line:match('%$([%w%d%p_]+)%$ = ([%w%d%p_]+)')

		if (name ~= nil) then
			log('set '..tostring(name)..' to '..tostring(val))

			vars[name] = val
		end
	end

	if (wc3path == nil) then
		wc3path = config.assignments['wc3path']
	end

	vars['MAP'] = mapPath
	vars['WC3'] = wc3path

	for i = 1, #extCalls, 1 do
		local extCall = extCalls[i]

		local tmpFile = nil
		local tmpFileName

		if (wc3path == nil) then
			tmpFileName = io.local_dir()..'tmpFile.tmp'
		else
			tmpFileName = wc3path..'\\postproc.tmp'
		end

		local resLevel = nil

		vars['FILENAME'] = tmpFileName

		local args = {}

		for i = 1, #extCall.args, 1 do
			local arg = extCall.args[i]

			local varName = arg:match('%$(.*)%$')

			if (varName ~= nil) then
				local varVal = vars[varName]

				if varVal then
					arg = varVal
				end
			end

			args[i] = arg
		end
		
		if (extCall.lines ~= nil) then
			tmpFile = io.open(tmpFileName, 'w+')

			tmpFile:write(table.concat(extCall.lines, '\n'))
			
			tmpFile:close()
		end
		
		if not runTool(extCall.name, args) then
			break
		end
	end
end

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

		log(throwErrorMsg)
	end

	postprocLog:close()
	if (logPipe ~= nil) then
	--osLib.pause()
	--logPipe:close()
	end

	error(table.concat(t, '\n'), 0)
end

postprocLog:close()
if (logPipe ~= nil) then
	logPipe:close()
end

return true, noDefaultTools