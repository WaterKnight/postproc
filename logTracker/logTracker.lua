--package.path = [[.\?\init.lua]]..';'..package.path
package.path = [[..\?.lua]]..';'..package.path

require 'orient'

local config = dofile('..\\postproc_getconfigs.lua')

local s=io.toAbsPath(config.assignments['waterlua'], string.reduceFolder(io.local_dir()))

requireDir(s)

osLib.clearScreen()

require 'socket'

function sleep(timeout)
	socket.sleep(timeout)
end

local params = {...}

local wc3path = params[1]
local waitSignal = params[2]
local customPath = params[3]

if (wc3path == '') then
	wc3path = nil
end
if (customPath == '') then
	customPath = nil
end

assert(wc3path, 'no wc3path')

wc3path = io.toFolderPath(wc3path)

local wc3logsPath = wc3path..[[Logs\]]

local function convLine(line)
	if (line == nil) then
		return nil
	end

	local newLine = line:match([[^%c*%s*call%s*Preload%(%s*""%s*%)(.*)" %)$]])

	if (newLine ~= nil) then
		newLine = newLine:gsub([[\\]], [[\]])
	end

	return newLine
end

local function parseSingleVal(line)
	local res = nil
	local t = line:split('\n')
	local i = 1

	while ((res == nil) and (i <= #t)) do
		res = convLine(t[i])

		i = i + 1
	end

	return res
end

if waitSignal then
	local signalPath = wc3path..[[Logs\logTracker_signal.ini]]

	os.remove(signalPath)

	print(string.format("waiting for signal... (%s)", signalPath))

	while (file == nil) do
		sleep(0.1)
		file = io.open(signalPath, "r")
	end

	targetPath = parseSingleVal(file:read('*a'))

	file:close()

	os.remove(signalPath)

	assert(targetPath, 'invalid value in signal path')

	print(string.format('take from signal (%s)', targetPath))
else
	local f = io.open(wc3logsPath..[[logTracker_lastPath.ini]], 'r')

	if (f ~= nil) then
		targetPath = parseSingleVal(f:read('*a'))

		f:close()

		assert(targetPath, 'invalid value in last path')

		print(string.format('take last path (%s)', targetPath))
	end
end

if (customPath ~= nil) then
	targetPath = customPath

	print(string.format('switch to customPath (%s)', targetPath))
end

assert(targetPath, 'no targetPath')

targetPath = io.toAbsPath(targetPath, wc3path)

local f = io.open(wc3logsPath..[[logTracker_lastPath.ini]], 'w+')

assert(f, 'cannot open '..wc3logsPath..[[logTracker_lastPath.ini]])

f:write(targetPath)

f:close()

if not targetPath:match('\\$') then
	targetPath = targetPath..'\\'
end

print(string.format('targetPath is %s', targetPath))

local function readSessionId()
	local filePath = targetPath..[[index.ini]]

	local file = io.open(filePath, "r")

	assert(file, "cannot open "..filePath)

	local input = file:read("*a")

	local search = [[SetPlayerName%(GetLocalPlayer%(%), "(%d+)"%)]]

	local pos, posEnd, sessionId = input:find(search)

	file:close()

	return sessionId
end

local sessionId = readSessionId()

print("sessionId: "..sessionId)

os.execute("mode con:lines=550")
os.execute(string.format('title logTracker %s session %s', targetPath, sessionId))

local lines = {}
local linesC = 0

fileMaxLines = 500 - 1

local fileIndex = 0

local mergesLinesI
local mergesLinesTable

while true do
	local fileLines = {}
	local fileLinesC = 0
	local filePath = targetPath..[[Session]]..sessionId..[[\log_]]..fileIndex..[[.txt]]

	print(string.format('listening to %s...', filePath))

	mergesLinesI = 0

	while (fileLinesC < fileMaxLines) do
		local file = io.open(filePath, "rb")

		while (file == nil) do
			sleep(0.1)

			file = io.open(filePath, "rb")
		end

		fileLinesC = 0

		local rawString = file:read("*a")

		local rawLines = rawString:split(string.char(13)..string.char(10))

		--local rawLine = file:read()
		local rawLineI = 1

		local rawLine = rawLines[1]

		while rawLine do
			local line = convLine(rawLine)

			if line then
				fileLinesC = fileLinesC + 1
				fileLines[fileLinesC] = line
			end

			--rawLine = file:read()
			rawLineI = rawLineI + 1
			rawLine = rawLines[rawLineI]
		end

		file:close()

		for i = linesC % fileMaxLines + 1, fileLinesC, 1 do
			local line = fileLines[i]

			linesC = linesC + 1
			lines[linesC] = line

			local pos, posEnd = line:find(":cmd")

			if (pos == 1) then
				local t = line:sub(posEnd + 1):split(" ")

				for i = 1, #t, 1 do
					local field
					local val

					local pos, posEnd = t[i]:find("=")

					if pos then
						field = t[i]:sub(1, pos - 1)
						val = t[i]:sub(posEnd + 1)
					end

					if (field == "mergeLines") then
						mergesLinesI = tonumber(val)
						mergesLinesTable = {}
					end
				end
			else
				if (mergesLinesI > 0) then
					mergesLinesI = mergesLinesI - 1
					mergesLinesTable[#mergesLinesTable + 1] = line

					if (mergesLinesI == 0) then
						print(table.concat(mergesLinesTable, ""))
					end
				else
					print(line)
				end
			end
		end

		sleep(0.1)
	end
print("next file")
	fileIndex = fileIndex + 1
end