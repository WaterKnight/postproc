local params = {...}

local log
local logDetailedPath

osLib = {}

osLib.pause = function()
	os.execute('pause')
end

osLib.createTimer = function()
	local this = {}

	function this:start()
		this.startPoint = os.clock()
	end

	function this:getElapsed()
		return (os.clock() - this.startPoint)
	end

	this:start()

	return this
end

osLib.clearScreen = function()
	io.flush(io.stdout)
	io.flush(io.stderr)

	os.execute('cls')

	print('clearing screen...')

	io.flush(io.stdout)
	io.flush(io.stderr)
end

os.setLogPaths = function(path, detailedPath)
	assert(path, 'no path')
	assert(detailedPath, 'no detailedPath')

	path = io.toAbsPath(path)
	detailedPath = io.toAbsPath(detailedPath)

	log = io.open(path, 'w+')
	logDetailedPath = detailedPath
end

local tempCallsDir = io.toAbsPath([[tempCalls\]], io.local_dir())

createDir(tempCallsDir)

--os.execute(string.format('rd 2>NUL %s /s /q', tempCallsDir:quote()))
--os.execute(string.format('mkdir 2>NUL %s', tempCallsDir:quote()))

local function toDOS(val)
	assert(val, 'no value')

	if (val == nil) then
		return [[""]]
	end

	if (type(val) ~= 'string') then
		return val
	end

	if (val:sub(val:len(), val:len()) == [[\]]) then
		val = val..[[\]]
	end

	val = val:gsub([["]], [[\"]])

	return [["]]..val..[["]]
end

osLib.ack = function()
	io.setGlobal('success', true)
end

osLib.run = function(cmd, args, options, fromFolder, doNotWait, name)
	cmd = cmd:gsub('/', '\\')

	local fileName = getFileName(cmd)
	local folder = getFolder(cmd)

	--if doNotWait then
	--	cmd = fileName
	--else
		if (folder and (folder ~= '')) then
			cmd = cmd:quote()
		end
	--end

	if options then
		for k, v in pairs(options) do
			v = tostring(v)

			options[k] = '/'..v
		end

		options = table.concat(options, ' ')

		cmd = cmd..' '..options
	end

	if args then
		for k, v in pairs(args) do
			v = tostring(v)

			--args[k] = v:quote()
			args[k] = toDOS(v)
		end

		args = table.concat(args, ' ')

		cmd = cmd..' '..args
	end

	local tempCPath = 'tempC'

	local f = io.local_open(tempCPath, 'r')
	local tempC

	if f then
		tempC = tonumber(f:read())

		f:close()
	else
		tempC = 0
	end

	tempC = tempC + 1

	local f = io.local_open(tempCPath, 'w+')

	f:write(tempC)

	f:close()

	local tempFilePath = io.toAbsPath(tempCallsDir..[[temp]]..tempC..[[.bat]])

	local file = io.open(tempFilePath, 'w+')

	assert(file, 'cannot open '..tempFilePath)

	local lines = {}

	if (fromFolder and (fromFolder ~= '')) then
		lines[#lines + 1] = string.format('cd /d %s', fromFolder:quote())
	end

	local successFilePath = tempCallsDir..[[success]]

	local returnOutputFilePath = tempCallsDir..[[outMsg.txt]]
	local returnErrorMsgFilePath = tempCallsDir..[[errorMsg.txt]]

	removeFile(returnOutputFilePath)
	removeFile(returnErrorMsgFilePath)

	cmd = cmd..' 1>'..returnOutputFilePath:quote()..' 2>'..returnErrorMsgFilePath:quote()

	if doNotWait then
		--lines[#lines + 1] = cmd
		lines[#lines + 1] = 'echo success > '..successFilePath:quote()

		lines[#lines + 1] = 'set ERRORLEVEL='

		if name then
			lines[#lines + 1] = '@echo | call '..cmd
		else
			lines[#lines + 1] = cmd
		end

		lines[#lines + 1] = 'if %ERRORLEVEL% NEQ 0 del '..successFilePath:quote()

		lines[#lines + 1] = 'exit'
	else
		lines[#lines + 1] = 'echo success > '..successFilePath:quote()

		lines[#lines + 1] = 'set ERRORLEVEL='

		if name then
			lines[#lines + 1] = '@echo | call '..cmd
		else
			lines[#lines + 1] = cmd
		end

		lines[#lines + 1] = 'if %ERRORLEVEL% NEQ 0 del '..successFilePath:quote()

		lines[#lines + 1] = 'exit'
	end

	file:write(table.concat(lines, '\n'))

	file:close()

	local result
	os.execute('@echo OFF')

	local function exec(cmd)
		io.setGlobal('success', false)

		os.execute(cmd)

		--result = io.getGlobal('success')
		result = io.pathExists(successFilePath)

		io.setGlobal('success', nil)
	end

	if doNotWait then
		--exec(string.format('start /wait /min %s 2>>NUL', tempFilePath:quote()))
		exec(string.format('start /min %s %s >> NUL'..' 2>>NUL', name:quote(), tempFilePath:quote()))
	else
		if (name == nil) then
			name = ''
		end

		if logDetailedPath then
			exec(string.format('start /wait /min %s %s >> %s 2>>NUL', name:quote(), tempFilePath:quote(), logDetailedPath:quote()))
		else
			exec(string.format('start /wait /min %s %s >> NUL'..' 2>>NUL', name:quote(), tempFilePath:quote()))
		end
	end

	os.execute('@echo ON')

	local errorMsg = nil
	local outMsg = nil

	local f = io.open(returnOutputFilePath, 'r')

	if (f ~= nil) then
		outMsg = f:read('*a')

		f:close()
	end

	local f = io.open(returnErrorMsgFilePath, 'r')

	if (f ~= nil) then
		errorMsg = f:read('*a')

		f:close()
	end

	return result, errorMsg, outMsg
end

osLib.waitForKeystroke = function()
	local folder = io.local_dir()

	local outPath = folder..'waitForKeystrokeOut.txt'

	removeFile(outPath)

	local cmd = 'call '..(folder..'waitForKeystroke.exe'):quote()..' '..outPath:quote()..' >NUL'

	os.execute(cmd)

	local f = io.open(outPath, 'r')

	assert(f, 'cannot open '..outPath)

	local result = f:read('*a')

	f:close()

	return result
end

osLib.runProg = function(interpreter, path, args, options, doNotWait, fromFolder)
	path = io.toAbsPath(path, io.local_dir(1))

	local folder = getFolder(path)
	local fileName = getFileName(path)

	if interpreter then
		if args then
			local tmp = {}

			for k, v in pairs(args) do
				tmp[k] = v
			end

			for k, v in pairs(tmp) do
				args[k + 1] = v
			end
		else
			args = {}
		end

		args[1] = fileName
	end

	if (fromFolder == nil) then
		fromFolder = folder
	end

	local t = osLib.createTimer()

	print('run '..path)

	local result = nil
	local errorMsg = nil
	local outMsg = nil

	if interpreter then
		result, errorMsg, outMsg = osLib.run(interpreter, args, options, fromFolder, doNotWait, nil)
	else
		result, errorMsg, outMsg = osLib.run(path, args, options, fromFolder, doNotWait, path)
	end

	if log then
		print('log ', log)

		log:write('finished '..path..' after '..math.cutFloat(t:getElapsed())..' seconds'..'\n')
	end

	local resultMsg

	if result then
		resultMsg = 'success'
	else
		resultMsg = 'failure'
	end

	io.write(' - '..math.cutFloat(t:getElapsed())..'seconds, '..resultMsg..'\n')

	return result, errorMsg, outMsg
end

osLib.exit = function(val)
	if (val == 0) then
		io.setGlobal('success', true)
	end

	os.exit(val)
end

osLib.clearTempCalls = function()
	removeDir(tempCallsDir)
	io.setGlobal('tempC')
end