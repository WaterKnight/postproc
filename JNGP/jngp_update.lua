local params = {...}

local paramsMap = params[1]

local postprocDir = paramsMap['postprocDir']

assert(postprocDir, 'no postprocDir')

local updatePath = postprocDir..'postproc_update.lua'

local f = loadfile(updatePath)

local result, errMsg, outMsg = f()

if not result then
	error(errMsg)
end