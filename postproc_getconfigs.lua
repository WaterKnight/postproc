local function script_path()
	local str = debug.getinfo(2, "S").source:sub(2)

	str = str:gsub('/', '\\')

	local dir = str:match("(.*\\)")

	if (dir == nil) then
		return ''
	end

	return dir
end

local function createConfig()
	local this = {}

	this.assignments = {}
	this.sections = {}

	function this:readFromFile(path, ignoreNotFound)
		assert(path, 'configParser: no path passed')

		local f = io.open(path, 'r')

		if not ignoreNotFound then
			assert(f, 'configParser: cannot open file '..tostring(path))
		end

		local curSection = nil

		for line in f:lines() do
			line = line:gsub('\\\\', '\\')

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
					local vals = {}

					for val in val:gmatch("\"(.-)\"") do
						vals[#vals + 1] = val
					end

					if (#vals > 1) then
						val = vals
					else
						val = vals[1]
					end
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

config:readFromFile(script_path()..'config.conf')

return config