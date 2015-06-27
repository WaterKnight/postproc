local params = {...}

local paramsMap = params[1]

local mapPath = paramsMap['mapPath']
local postprocDir = paramsMap['postprocDir']

assert(mapPath and mapPath:len() > 0, 'no mapPath')
assert(postprocDir, 'no postprocDir')

local pullInstructionsPath = postprocDir..'postproc_pullInstructions.lua'

local f = loadfile(pullInstructionsPath)

f(mapPath, true)