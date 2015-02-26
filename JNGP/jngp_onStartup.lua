local params = {...}

local config = params[1]
local paramsMap = params[2]

assert(config, 'no config')
assert(paramsMap, 'no paramsMap')

local outputPathNoExt = paramsMap['outputPathNoExt']

assert(outputPathNoExt, 'no outputPathNoExt')

os.remove(outputPathNoExt..'.w3m')
os.remove(outputPathNoExt..'.w3x')