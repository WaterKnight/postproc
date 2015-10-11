requireRemote = function(path)
	if (package.loaded[path] ~= nil) then
		return
	end

	local http = require 'socket.http'
	local ltn12 = require 'ltn12'

	local t = {}

	local req = {
		url = 'http://www.moonlightflower.net/index.html',
		sink = ltn12.sink.table(t)
	}

	local response, status, header = http.request(req)

	local s = table.concat(t)

	local f = loadstring(s)

	return f()
end

--requireRemote('postproc/')

local md5lib = require 'libmd5'

dofile(io.local_dir()..'makeChecksums.lua')

local files = {}

local function defFile(path)
	path = path:gsub('/', '\\')

	if (files[path] ~= nil) then
		return files[path]
	end

	local file = {}

	files[path] = file

	file.path = path

	return file
end

--local files
local f = io.open('checksums.txt', 'r')

local s = f:read('*a')

f:close()

local t = s:split('\n')

local checksums = {}

for _, line in pairs(t) do
	local checksum, path = line:match('([^%s]+)%s+(.+)')

	if ((path ~= nil) and (checksum ~= nil)) then
		local file = defFile(path)

		file.localChecksum = checksum
	end
end

--remote files
local http = require 'socket.http'

local t = {}

local req = {
	host = 'inwcfunmap.bplaced.net',
	path = '/postproc/updater/checksums.txt',
	type = 'i',
	sink = ltn12.sink.table(t)
}

local response, status, header = http.request(req)

assert((status == 200), string.format('could not read remote checksums.txt (%s)', status))

--[[local ftp = require 'socket.ftp'

local t = {}

local req = {
	scheme = 'ftp',
	authority = 'inwcfunmap.bplaced.net',
	user = 'anonymous',
	password = 'anonymous',
	host = 'inwcfunmap.bplaced.net',
	path = '/postproc/updater/checksums.txt',
	type = 'i',
	sink = ltn12.sink.table(t)
}

print(ftp.get(req))]]

os.execute("pause")

local t = table.concat(t):split('\n')

for _, line in pairs(t) do
	local checksum, path = line:match('([^%s]+)%s+(.+)')

	if ((path ~= nil) and (checksum ~= nil)) then
		local file = defFile(path)

		file.remoteChecksum = checksum
	end
end

local postprocDir = orient.reduceFolder(io.local_dir())

for _, file in pairs(files) do
	local pullFile = false

	if (file.remoteChecksum == nil) then
		print('remove', file.path)
	elseif (file.localChecksum == nil) then
		print('add', file.path)
		pullFile = true
	elseif (file.remoteChecksum ~= file.localChecksum) then
		print('update', file.path)
		pullFile = true
	end

	if pullFile then
		local http = require 'socket.http'

		local t = {}

		local req = {
			host = 'inwcfunmap.bplaced.net',
			path = string.format('/postproc/%s', file.path),
			type = 'i',
			sink = ltn12.sink.table(t)
		}

		local response, status, header = http.request(req)

		if (status == 200) then
			print(string.format('downloaded file %s', file.path))

			local targetPath = postprocDir..file.path

			io.createFile(targetPath)

			local f = io.open(targetPath, 'w')

			table.write(f, t)

			f:close()
		else
			print(string.format('failed to download file %s (%s)', file.path, status))
		end
	end
end