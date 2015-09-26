local md5lib = require 'libmd5'

--[[local t = {}

local req = {
	url = 'http://www.moonlightflower.net/index.html',
	sink = ltn12.sink.table(t)
}

local response, status, header = http.request(req)

local s = table.concat(t)]]

local f = io.open('checksums.txt', 'r')

local s = f:read('*a')

f:close()

local t = s:split('\n')

local checkSums = {}

for _, line in pairs(t) do
	local checkSum, path = line:match('([^%s]+)%s+(.+)')

	if ((path ~= nil) and (checkSum ~= nil)) then
		checkSums[path] = checkSum
	end
end

local postprocDir = orient.reduceFolder(io.local_dir())

print(postprocDir)

for _, path in pairs(io.getFiles(postprocDir, '*')) do
	for path in pairs(checkSums) do
		local status, curCheckSum = md5.digest(postprocDir..path)

		if (status == 0) then
			if (curCheckSum ~= checkSums[path]) then
				print('need to replace', path)

				local ftp = require 'socket.ftp'

				local req = socket.url.parse(path)

				local t = {}

				req.type = 'i'
				req.sink = ltn12.sink.table(t)

				ftp.get(req)
			end
		else
			print('could not digest', curCheckSum)
		end
	end
end

os.execute("pause")