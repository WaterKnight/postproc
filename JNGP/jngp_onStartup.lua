local params = {...}

local paramsMap = params[1]

assert(paramsMap, 'no paramsMap')

local postprocDir = paramsMap['postprocDir']

assert(postprocDir, 'no postprocDir')

require 'waterlua'

local tempDir = postprocDir..[[temp\]]

--removeDir(tempDir)

local outputPathNoExt = paramsMap['outputPathNoExt']

assert(outputPathNoExt, 'no outputPathNoExt')

os.remove(outputPathNoExt..'.w3m')
os.remove(outputPathNoExt..'.w3x')