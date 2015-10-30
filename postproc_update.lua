require 'waterlua'

local params = {...}

local result, errMsg, outMsg = osLib.runProg(nil, 'postprocInstaller.exe')

return result, errMsg, outMsg