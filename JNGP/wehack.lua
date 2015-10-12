local function createConfig()
	local this = {}

	this.assignments = {}
	this.sections = {}

	function this:readFromFile(path, ignoreNotFound)
		assert(path, 'configParser: no path passed')

		local f = io.open(path, 'r')

		if not ignoreNotFound then
			assert(f, 'configParser: could not open file '..tostring(path))
		end

		local curSection = nil

		for line in f:lines() do
			local sectionName = line:match('%['..'([%w%d%p_]*)'..'%]')

			if (sectionName ~= nil) then
				curSection = this.sections[sectionName]

				if (curSection == nil) then
					curSection = {}

					this.sections[sectionName] = curSection

					curSection.assignments = {}
					curSection.lines = {}
				end
			elseif (curSection ~= nil) then
				curSection.lines[#curSection.lines + 1] = line
			end

			local pos, posEnd = line:find('=')

			if pos then
				local name = line:sub(1, pos - 1)
				local val = line:sub(posEnd + 1, line:len())

				if ((type(val) == 'string')) then
					val = val:match("\"(.*)\"")
				end

				if (curSection ~= nil) then
					curSection.assignments[name] = val
				else
					this.assignments[name] = val
				end
			end
		end

		f:close()
	end

	return this
end

local config = createConfig()

local configPath = 'postproc.conf'

config:readFromFile(configPath)

local postprocDir = config.assignments['postprocDir']
local wehackVersion = config.assignments['wehackVersion']

assert(postprocDir, [[no assignment 'postprocDir' in config]])
assert(wehackVersion, [[no field 'wehackVersion' in config]])

local function toFolderPath(path, shortened)
	assert(path, 'no path')

	path = path:gsub('/', '\\')

	if shortened then
		path = path:match('(.*)\\$') or path
	else
		if not path:match('\\$') then
			path = path..'\\'
		end
	end

	return path
end

postprocDir = toFolderPath(postprocDir)

local function dofile(path, ...)
	arg = {[0] = path, ...}

	local f = loadfile(path)

	assert(f, string.format('could not load %s', path))

	return f(...)
end

dofile(postprocDir..'JNGP\\jnpg_init.lua', wehackVersion)