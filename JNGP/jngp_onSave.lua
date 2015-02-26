local params = {...}

local config = params[1]
local paramsMap = params[2]

assert(config, 'no config')
assert(paramsMap, 'no paramsMap')

local mapPath = paramsMap['mapPath']
local outputPathNoExt = paramsMap['outputPathNoExt']

assert(mapPath, 'no mapPath')
assert(outputPathNoExt, 'no outputPathNoExt')

local ext = mapPath:match('%.[^%..]*$') or ''

local outputPath = outputPathNoExt..ext

local postprocDir = paramsMap['postprocDir']

assert(postprocDir, 'no postprocDir')

local postprocPath = postprocDir..'postproc.lua'

assert(postprocPath, 'no postprocPath')

local postproc, loadErr = loadfile(postprocPath)

assert(postproc, 'cannot load '..tostring(postprocPath)..'\n'..tostring(loadErr))

return postproc(mapPath, outputPath, nil, paramsMap['wc3path'], paramsMap['configPath'], paramsMap['logPath'])