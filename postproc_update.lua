require 'waterlua'

local params = {...}

local result, errMsg, outMsg = osLib.runProg(nil, 'luaLauncher.exe')

return result, errMsg, outMsg