require 'orient'

local config = dofile(script_path()..'postproc_getconfigs.lua')

addPackagePath(script_path()..'?')

local waterluaPath = config.assignments['waterlua']

assert(waterluaPath, 'no waterlua path found')

requireDir(io.toAbsPath(waterluaPath, io.local_dir()))

require 'waterlua'

print(package.cpath)

local t = {}

local yourOs = t[extension]

assert(yourOs, 'unknown operating system, abort')

if (yourOs == 'win') then
	os.execute(string.format('setx postproc %s', (io.local_dir()..'\\'):quote()))
elseif (yourOs == 'linux') then
	os.execute(string.format('export postproc=%s', (io.local_dir()..'\\'):quote()))
elseif (yourOs == 'mac') then
	os.execute(string.format('export postproc=%s', (io.local_dir()..'\\'):quote()))
end