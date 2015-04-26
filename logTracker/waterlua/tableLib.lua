function totable(t)
	if (t == nil) then
		return nil
	end

	if (type(t) == 'table') then
		return t
	end

	return {t}
end

function tableToLua(t)
	local res = {}

	for k, v in pairs(t) do
		if (type(v) == 'table') then
			res[#res + 1] = tableToLua(v)
		else
			if (type(v) == 'string') then
				v = string.format('%q', v)
			else
				v = tostring(v)
			end
		end

		if (type(k) == 'number') then
			res[#res + 1] = v
		else
			res[#res + 1] = k..'='..v
		end
	end

	return '{'..table.concat(res, ', ')..'}'
end

function tableContains(t, e)
	if (t == nil) then
		return false
	end

	for k, v in pairs(t) do
		if (v == e) then
			return true
		end
	end

	return false
end

function getTableSize(t, nested, recursionTable)
	assert(t, 'no arg')

	assert((type(t) == 'table'), 'no table')

	if (recursionTable == nil) then
		recursionTable = {}
	end

	if recursionTable[t] then
		return 0
	end

	recursionTable[t] = t

	local c = 0

	for k, val in pairs(t) do
		if (nested and (type(val) == "table")) then
			c = c + getTableSize(val, true, recursionTable) + 1
		else
			c = c + 1
		end
	end

	return c
end

function copyTable(source, recursionTable)
	if (recursionTable == nil) then

		recursionTable = {}
	end

	if recursionTable[source] then

		return recursionTable[source]
	end

	local result

	if (source == nil) then
		return nil
	end

	result = {}

	recursionTable[source] = result

	for k, v in pairs(source) do
		if (type(v) == "table") then
			local add = copyTable(v, recursionTable)

			if (k == v) then
				k = add
			end

			result[k] = add
		else
			result[k] = v
		end
	end

	return result
end

function mergeTable(source, toAdd)
	for k, v in pairs(toAdd) do
		if v then
			if (type(v) == "table") then
				if (type(source[k]) ~= "table") then
					source[k] = {}
				end

				mergeTable(source[k], v)
			else
				source[k] = v
			end
		end
	end
end

io.local_require('stringLib')

function printTable(t, nestDepth)
	if (nestDepth == nil) then
		nestDepth = 0
	end

	for k, v in pairs(t) do
		if (type(v) == "table") then
			print(string.rep("\t", nestDepth).."//"..k)

			printTable(v, nestDepth + 1)
		else
			if (type(v) == "boolean") then
				v = boolToString(v)
			end

			print(string.rep("\t", nestDepth)..k.." --> "..tostring(v))
		end
	end
end

function writeTable(file, root, nestDepth)
	local recursionTable = {}

	file:write("contents of ", tostring(root), "\n")

	local function writeTable_nest(t, nestDepth)
		if recursionTable[t] then
			file:write("recursion ", tostring(t), "\n")

			return--error("writeTable: recursion in table")
		end

		recursionTable[t] = t

		for k, v in pairs(t) do
			if (type(v) == "table") then
				file:write(string.rep("\t", nestDepth).."//"..k.."\n")

				writeTable_nest(v, nestDepth + 1)
			else
				if (type(v) == "boolean") then
					v = boolToString(v)
				end

				file:write(string.rep("\t", nestDepth)..k.." --> "..tostring(v).."\n")
			end
		end
	end

	if (nestDepth == nil) then
		nestDepth = 0
	end

	writeTable_nest(root, nestDepth)
end

table.mix = function(t1, t2, sep)
	if (sep == nil) then
		sep = ""
	end

	local result = {}

	for i = 1, #t1, 1 do
		result[i] = t1[i]..t2[i]
	end

	return result
end

function addToEnv(t)
	setmetatable(t, {__index = _G})
	setfenv(2, t)
end