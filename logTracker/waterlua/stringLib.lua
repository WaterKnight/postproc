function tobool(s)
	if (s == "true") then
		return true
	end
	if (s == "false") then
		return false
	end

	return nil
end

function boolToString(b)
	if b then
		return "true"
	end

	return "false"
end

function stringToType(val, type)
	assert(val, 'no value')
	assert(type, 'no type')

	if (type == 'boolean') then
		return tobool(val)
	end
	if (type == 'number') then
		return tonumber(val)
	end

	assert((type ~= 'table'), 'cannot convert to table')

	return val
end

string.endsWith = function(s, target)
	return (s:sub(s:len() - target:len() + 1, s:len()) == target)
end

string.trimStartWhitespace = function(s)
  return s:gsub("^%s*(.-)%s*$", "%1")
end

string.trimSurroundingWhitespace = function(s)
	local pos = s:find("[^ \t]")

	local posEnd = s:len() - s:reverse():find("[^ \t]") + 1

	return s:sub(pos, posEnd)
end

string.trim = function(s, rem)
    while s:find(rem, 1, true) do
        s = s:sub(1, s:find(rem, 1, true) - 1)..s:sub(s:find(rem, 1, true) + 1)
    end

    return s
end

string.quote = function(s)
	return '\"'..s..'\"'
end

string.dequote = function(s)
	s = s:gsub('"', '')

	return s
end

string.split = function(s, delimiter)
	if (s == nil) then
		return nil
	end
	if (s == '') then
		return {}
        end

	if (type(s) ~= 'string') then
		s = tostring(s)
	end

	local results = {}
	local resultsCount = 0
	
	while s:find(delimiter) do
	    resultsCount = resultsCount + 1
	
	    results[resultsCount] = s:sub(1, s:find(delimiter) - 1)
	
	    s = s:sub(s:find(delimiter) + 1)
	end
	
	resultsCount = resultsCount + 1
	
	results[resultsCount] = s
	
	return results
end

string.doubleBackslashes = function(s)
    return s:gsub('\\', '\\\\')
end

--[[string.lastFind = function(s, target)
	local result = 0

	while s:find(target, result + 1, true) do
		result = s:find(target, result + 1, true)
	end

	if (result == 0) then
		return nil
	end

	return result
end]]

string.lastFind = function(s, target)
	local lastPos, lastPosEnd
	local pos, posEnd = s:find(target)

	while pos do
		lastPos, lastPosEnd = pos, posEnd

		pos, posEnd = s:find(target, posEnd + 1)
	end

	return lastPos, lastPosEnd
end

function concat(a, b)
	return (tostring(a)..tostring(b))
end

function isPlainText(s)
	assert(s, 'no value')
	assert(type(s) == 'string', 'value is not a string '..'('..table.concat({tostring(s)}, ', ')..')')

	if s:find('\\') then
		return true
	end

	while s:find('.', 1, true) do
		s = s:sub(s:find('.', 1, true) + 1)
	end

	if (s == '') then
		return true
	end
	if (tonumber(s) or ((s:sub(1, 1) == "'") and (s:sub(s:len(), s:len()) == "'"))) then
		return false
	end
	if (s:len() == 4) then
		return true
	end

	local c = 1

	local ch = s:sub(c, c)

	while ((((ch >= 'A') and (ch <= 'Z')) or tonumber(ch) or (ch == '_')) and (c <= s:len())) do
		c = c + 1

		ch = s:sub(c, c)
	end

	if (c > s:len()) then
		return false
	end

	return true
end

string.isWhitespace = function(s, ex)
	if ex then
		return (s:match'^%s*(.*)' == "")
	end

	return (s == "")
end

string.debracket = function(s, startToken, endToken)
	if (s:sub(1, 1) == startToken) then
		s = s:sub(2, s:len())
	end
	if (s:sub(s:len(), s:len()) == endToken) then
		s = s:sub(1, s:len() - 1)
	end

	return s
end

function debracket(s, startToken, endToken)
	return s:debracket(startToken, endToken)
end

local chars = {}

for i = 0, 9, 1 do
	chars[i] = i
end

chars[10] = "A"
chars[11] = "B"
chars[12] = "C"
chars[13] = "D"
chars[14] = "E"
chars[15] = "F"
chars[16] = "G"
chars[17] = "H"
chars[18] = "I"
chars[19] = "J"
chars[20] = "K"
chars[21] = "L"
chars[22] = "M"
chars[23] = "N"
chars[24] = "O"
chars[25] = "P"
chars[26] = "Q"
chars[27] = "R"
chars[28] = "S"
chars[29] = "T"
chars[30] = "U"
chars[31] = "V"
chars[32] = "W"
chars[33] = "X"
chars[34] = "Y"
chars[35] = "Z"

charsC = 36

function getAscii(val, digits)
	local c = val
	local s = ""

	for i = 3, 0, -1 do
		local val = math.floor(c / math.pow(charsC, i))

		s = s..chars[val]

		c = c % math.pow(charsC, i)
	end

	return s:sub(s:len() - digits + 1, s:len())
end

string.findInner = function(s, startDel, endDel)
	local searchPat = "%b"..startDel..endDel

	local startPos, endPos = string.find(s, searchPat)

	if not startPos then
		return nil, nil
	end

	local newStartPos, newEndPos = string.find(s, searchPat, startPos + 1)

	while (newEndPos and (newEndPos < endPos)) do
		startPos = newStartPos
		endPos = newEndPos

		newStartPos, newEndPos = string.find(s, searchPat, startPos + 1)
	end

	return startPos, endPos
end

string.splitOuter = function(s, delimiter, encaps)
	if (s == nil) then
		return nil
	end
	if (s == "") then
		return {}
	end

	if (type(s) ~= "string") then
		s = tostring(s)
	end

	local s2 = s

	for i = 1, #encaps, 1 do
		local pos, posEnd = s2:findInner(encaps[i][1], encaps[i][2])

		while pos do
			s2 = s2:sub(1, pos - 1)..string.rep("#", encaps[i][1]:len())..s2:sub(pos + 1, posEnd - 1):gsub(delimiter, string.rep("#", delimiter:len()))..string.rep("#", encaps[i][2]:len())..s2:sub(posEnd + 1, s2:len())

			pos, posEnd = s2:findInner(encaps[i][1], encaps[i][2])
		end
	end

	local results = {}

	local pos, posEnd = s2:find(delimiter, 1, true)
	local lastPosEnd = 0

	while pos do
		results[#results + 1] = s:sub(lastPosEnd + 1, pos - 1)

		lastPosEnd = posEnd

		pos, posEnd = s2:find(delimiter, posEnd + 1, true)
	end

	results[#results + 1] = s:sub(lastPosEnd + 1, s:len())

	return results
end

function nilToString(s, inval)
	if (s == nil) then
		return tostring(inval)
	end

	return tostring(s)
end

function valToLua(val)
	if (val == nil) then
		return 'nil'
	end

	if (type(val) == 'table') then
		return tableToLua(val)
	end
	if (type(val) == 'boolean') then
		return boolToString(val)
	end
	if (type(val) == 'number') then
		return tostring(val)
	end
	if (type(val) == 'string') then
		return string.format('%q', val)
	end

	return nil
end