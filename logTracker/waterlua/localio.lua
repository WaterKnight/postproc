require 'lfs'
require 'stringLib'

function getFileName(path, noExtension)
	assert(path, 'no path')

	path = path:gsub('/', '\\')

	path = path:match('\\([^\\]*)$') or path

	if noExtension then
		path = path:match('([^%..]*)')
	end

	return path
end

function getFolder(path)
	assert(path, 'no path')

	path = path:gsub('/', '\\')

	path = path:match('(.*\\)')

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

function getWorkingDir()
	return io.popen([[cd]]):read("*l")
end

function getScriptDir()
	return getFolder(debug.getinfo(1).source:sub(1))
end

--

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

local function toFolderPath(path, shortened)
	assert(path, 'no path')

	path = path:gsub('/', '\\')

	if shortened then
		path = path:match('(.*)\\$') or path
	else
		if not path:match('\\$') then
			path = path..'\\'
		end
	end

	return path
end

io.toFolderPath = function(path, shortened)
	return toFolderPath(path, shortened)
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
	local result = toAbsPath(path, basePath)

	return result
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

	path = path:match('(.*\\)') or ''

	if not io.isAbsPath(path) then
		path = io.curDir()..path
	end

	return path
end

io.pathExists = function(path)
	return (lfs.attributes(toAbsPath(path, io.local_dir(1))) ~= nil)
end

io.pathIsFile = function(path)
	return (lfs.attributes(toAbsPath(path, io.local_dir(1)), 'mode') == 'file')
end

io.pathIsOpenable = function(path)
	assert(path, 'no path')

	local f = io.open(path, 'r')

	local result = (f ~= nil)

	f:close()

	return result
end

io.pathIsLocked = function(path)
	if not io.pathExists(path) then
		return true
	end

	local f = io.open(path, 'a')

	if (f ~= nil) then
		f:close()

		return false
	end

	return true
end

io.local_require = function(path1)
	local path = toAbsPath(path1, io.local_dir(1))

	if package.loaded[path] then
		return
	end

	local packagePath = package.path

	package.path = getFolder(path)..'?.lua'
--print('require', path1, path, getFolder(path))
	local result = require(getFileName(path, true))

	package.path = packagePath

	return result
end

io.local_open = function(path, options)
--print('local_open', path, toAbsPath(path, io.local_dir(1)))
	return io.open(toAbsPath(path, io.local_dir(1)), options)
end

io.local_loadfile = function(path)
	return loadfile(toAbsPath(path, io.local_dir(1)))
end

--print(os.getenv('LUA_PATH'):split(';'))

function isFolderPath(path)
	if (path == '') then
		return false
	end
	if (getFolder(path) == '') then
		return false
	end

	if (getFolder(path) ~= path) then
		return false
	end

	return true
end

string.reduceFolder = function(s, amount)
	assert(s, 'no path')

	if (amount == nil) then
		amount = 1
	end

	if (amount == 0) then
		return s
	end

	local dir = getFolder(s:sub(1, getFolder(s):len() - 1))
	local fileName = getFileName(s)

	if (dir == nil) then
		return fileName
	end

	return string.reduceFolder(dir..fileName, amount - 1)
end

function getFiles(dir, filePath)
	local c = 0
	local t = {}

	local cmd = [[dir 2>NUL ]]..(dir..filePath):quote()..[[ /b /s]]

	for line in io.popen(cmd):lines() do
		if io.pathIsFile(line) then
			c = c + 1
			t[c] = line
		end
	end

	return t
end

function getScriptDir(level)
	if (level == nil) then
		level = 1
	end

	return getFolder(debug.getinfo(level).source:sub(1))
end

function changeWorkingDir(path)
	assert(path, "no path specified")

	os.execute([[cd /d ]]..path:quote())
end

function copyFile3(source, target)
	local sourceFile = io.open(source, "rb")
	local targetFile = io.open(target, "w+b")

	if (targetFile == nil) then
		os.execute([[mkdir ]]..getFolder(target):quote())

		targetFile = io.open(target, "w+b")
	end

	targetFile:write(sourceFile:read("*a"))

	sourceFile:close()
	targetFile:close()
end

function copyDir3(source, target)
	os.execute([[xcopy ]]..source:quote()..[[ ]]..target:quote()..[[ /e /i /y /q]])
end

function copyFile(source, target, overwrite)
	source = toAbsPath(source, io.local_dir(1))
	target = toAbsPath(target, io.local_dir(1))

	createDir(getFolder(target))

	if isFolderPath(target) then
		target = target..getFileName(source)
	end

	if not overwrite and io.pathExists(target) then
		print('copyFile: target path exists', target)

		return
	end

	local sourceFile = io.open(source, "rb")
	local targetFile = io.open(target, "w+b")

	assert(sourceFile, 'copyFile: cannot open source '..tostring(source))
	assert(targetFile, 'copyFile: cannot open target '..tostring(target))

	local bufSize = 10000
	local fileSize = io.getFileSize(source)

	while (fileSize > 0) do
		targetFile:write(sourceFile:read(math.min(bufSize, fileSize)))

		fileSize = fileSize - bufSize
	end

	sourceFile:close()
	targetFile:close()
end

function copyFileIfNewer(source, target)
	source = toAbsPath(source, io.local_dir(1))
	target = toAbsPath(target, io.local_dir(1))

	local targetMod = lfs.attributes(target, 'modification')

	if targetMod then
		local sourceMod = lfs.attributes(source, 'modification')

		if (targetMod >= sourceMod) then
			return
		end
	end

	copyFile(source, target, true)
end

function copyFile2(source, target)
	createDir(getFolder(target))

	local sourceFile = io.open(source, "rb")
	local targetFile = io.open(target, "w+b")

	assert(sourceFile, 'copyFile: cannot open sourcePath', sourcePath)
	assert(targetFile, 'copyFile: cannot open targetPath', targetPath)

	targetFile:write(sourceFile:read("*a"))

	sourceFile:close()
	targetFile:close()
end

function copyDir2(source, target)
	--os.execute([[xcopy ]]..source:quote()..[[ ]]..target:quote()..[[ /e /i /y /q]])
	source = io.toAbsPath(source, io.local_dir(1))
	target = io.toAbsPath(target, io.local_dir(1))

	assert(source, 'copyDir: no source', source)
	assert(target, 'copyDir: no target', target)

	local sourceFolder = getFolder(source)
	local targetFolder = getFolder(target)

	createDir(targetFolder)

	local iter = lfs.dir(source)

	assert(iter, 'copyDir: source is no directory', source)

	for path in iter do
		if ((path ~= '.') and (path ~= '..')) then
			copyFile(sourceFolder..path, targetFolder..path)
		end
	end
end

function copyDir(source, target, overwrite)
	--os.execute([[xcopy ]]..source:quote()..[[ ]]..target:quote()..[[ /e /i /y /q]])

	source = toFolderPath(source)
	target = toFolderPath(target)

	source = io.toAbsPath(source, io.local_dir(1))
	target = io.toAbsPath(target, io.local_dir(1))

	assert(source, 'copyDir: no source', source)
	assert(target, 'copyDir: no target', target)

	local sourceFolder = getFolder(source)
	local targetFolder = getFolder(target)

	local iter = lfs.dir(source)

	local t = {}

	for path in iter do
		t[#t + 1] = path
	end

	createDir(targetFolder)

	assert(iter, 'copyDir: source is no directory', source)

	for _, path in pairs(t) do
		if ((path ~= '.') and (path ~= '..')) then
			local sourcePath = sourceFolder..path
			local targetPath = targetFolder..path

			if io.pathIsFile(sourcePath) then
				copyFile(sourcePath, targetPath, overwrite)
			else
				sourcePath = toFolderPath(sourcePath)
				targetPath = toFolderPath(targetPath)

				copyDir(sourcePath, targetPath, overwrite)
			end
		end
	end
end

function getFilesEx(path)
	path = toAbsPath(path, io.local_dir(1))

	local iter = lfs.dir(path)

	local t = {}

	for targetPath in iter do
		if ((targetPath ~= '.') and (targetPath ~= '..')) then
			targetPath = path..targetPath

			if (lfs.attributes(targetPath, 'mode') == 'directory') then
				targetPath = targetPath..'\\'
			end

			t[#t + 1] = targetPath
		end
	end

	return t
end

function removeFile(path)
	path = toAbsPath(path, io.local_dir(1))

	os.remove(path)
end

function removeDir(path)
	path = toAbsPath(path, io.local_dir(1))

	assert(isFolderPath(path), 'removeDir: path is no directory '..tostring(path))

	local function nest(path)
		if ((path == nil) or (path == '')) then
			return
		end

		for _, targetPath in pairs(getFilesEx(path)) do
			nest(targetPath)
		end

		removeFile(path)
		lfs.rmdir(path)
	end

	nest(path)
end

function createDir(path)
	assert(path, 'no path')

	path = toAbsPath(path, io.local_dir(1))

	assert(isFolderPath(path), 'createDir: path is no directory '..tostring(path))

	local function nest(path)
		local p = toFolderPath(path, true)

		if ((path == nil) or (path == '') or lfs.mkdir(p)) then
			return
		end

		nest(path:reduceFolder())

		local result, errorMsg = lfs.mkdir(p)

		--print('result', result, errorMsg)
	end

	nest(path)
end

function flushDir(path)
	assert(path, 'no path')

	path = toAbsPath(path, io.local_dir(1))

	assert(isFolderPath(path), 'recreateDir: path is no directory '..tostring(path))

	removeDir(path)

	createDir(path)
end

io.getGlobal = function(name)
	local f = io.local_open(name, "r")

	if not f then
		return nil
	end

	local valType = f:read()
	local val = f:read()

	f:close()

	if (val == nil) then
		return valType
	end

	val = stringToType(val, valType)

	return val
end

io.setGlobal = function(name, val)
	if (val == nil) then
		removeFile(name)

		return
	end

	local valType = type(val)

	assert((valType ~= 'table'), 'cannot save table')

	local f = io.local_open(name, "w+")

	f:write(valType, '\n', tostring(val))

	f:close()
end

io.getFileSize = function(path)
	assert(path, 'no path')

	assert(io.pathExists(path), 'path '..tostring(path)..' does not exist')

	assert(io.pathIsOpenable(path), 'cannot open '..tostring(path))

	return lfs.attributes(path, 'size')
end

function syntaxCheck(path)
	assert(path, 'no path')

	local ring = rings.new()

	ring:dostring('package.path = '..valToLua(getFolder(path)..'?.lua'))

	local res, msg, trace = ring:dostring('require '..valToLua(getFileName(path, true)))

	return res, msg, trace
end