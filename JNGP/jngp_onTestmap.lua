local params = {...}

local config = params[1]
local paramsMap = params[2]

assert(config, 'no config')
assert(paramsMap, 'no paramsMap')

local cmdline = paramsMap['cmdline']
local postprocDir = paramsMap['postprocDir']
local wc3path = paramsMap['wc3path']
local outputPathNoExt = paramsMap['outputPathNoExt']
local forcePostproc = paramsMap['forcePostproc']
local startLogTracker = paramsMap['startLogTracker']

assert(cmdline, 'no cmdline')
assert(wc3path, 'no wc3path')
assert(outputPathNoExt, 'no outputPathNoExt')

local t = argsplit(cmdline)
local mapPath = nil

for i = 1, #t, 1 do
	if (t[i] == '-loadfile') then
		mapPath = t[i + 1]
	end
end

assert(mapPath, 'no mapPath')

mapPath = wc3path..'\\'..mapPath

string.lastFind = function(s, target)
	local lastPos, lastPosEnd
	local pos, posEnd = s:find(target)

	while pos do
		lastPos, lastPosEnd = pos, posEnd

		pos, posEnd = s:find(target, posEnd + 1)
	end

	return lastPos, lastPosEnd
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

function getFileExtension(path)
	assert(path, 'no path')

	local ext = getFileName(path):sub(getFileName(path, true):len() + 2, path:len())

	if (ext == '') then
		return nil
	end

	return ext
end

function copyFile(source, target, overwrite)
	local sourceFile = io.open(source, 'rb')
	local targetFile = io.open(target, 'w+b')

	assert(sourceFile, 'copyFile: cannot open source '..tostring(source))
	assert(targetFile, 'copyFile: cannot open target '..tostring(target))

	targetFile:write(sourceFile:read('*a'))

	sourceFile:close()
	targetFile:close()

	return true
end

local ext = mapPath:match('%.[^%..]*$') or ''

local outputPath = outputPathNoExt..ext

local doIt = false

if mapPath:match('^Maps\\Test\\') or mapPath:match('^'..wc3path..'\\Maps\\Test\\') then
	local outputFile = io.open(outputPath, 'rb')
	local mapFile = io.open(mapPath, 'rb')

	if ((outputFile ~= nil) and (mapFile ~= nil)) then
		local c = 0

		while ((c < 256) and (outputFile:read(1) == mapFile:read(1))) do
			c = c + 1
		end

		if (c >= 256) then
			doIt = true
		end
	end

	if (outputFile ~= nil) then
		outputFile:close()
	end
	if (mapFile ~= nil) then
		mapFile:close()
	end
else
	doIt = false
end

if doIt then
	local swapStrat = true

	if swapStrat then
		if not copyFile(outputPath, mapPath, true) then
			error('could not copy '..outputPath..' to '..mapPath)
		end
	else
		local t = argsplit(cmdline)

		for i = 1, #t, 1 do
			if (t[i] == '-loadfile') then
				t[i + 1] = outputPath
			end

			local arg = t[i]

			if (tonumber(arg) == nil) then
				if ((arg:sub(1, 1) ~= "-") and not ((arg:sub(1, 1) == "\"") and (arg:sub(arg:len(), arg:len()) == "\""))) then
					if (arg:sub(arg:len(), arg:len()) == "\\") then
						arg = arg .. "\\"
					end

					arg = "\"" .. arg .. "\""
				end
			end

			t[i] = arg
		end

		cmdline = table.concat(t, ' ')
	end
end

if ((doIt or forcePostproc) and startLogTracker) then
	local logTrackerCmd = [["]]..postprocDir..[[logTracker\logTrackerWait.bat]]..[[" "]]..wc3path..[["]]

	wehack.execprocess(logTrackerCmd)
end

return true, cmdline