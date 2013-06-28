---------------------------------
--! @file
--! @brief common string operations
---------------------------------

--! namespace
local str = {}

--! @brief Split text into a list consisting of the strings in text,
--! separated by strings matching delimiter (which may be a pattern). 
--! example: str.split(",%s*", "Anna, Bob, Charlie,Dolores")
--! like php explode
--! @param delimiter string
--! @param text string
--! @return table of stringparts
function str.split(delimiter, text)
  local list = {}
  local pos = 1
  if string.find("", delimiter, 1) then -- this would result in endless loops
    error("delimiter matches empty string!")
  end
  while 1 do
    local first, last = string.find(text, delimiter, pos)
    if first then -- found?
      table.insert(list, string.sub(text, pos, first-1))
      pos = last+1
    else
      table.insert(list, string.sub(text, pos))
      break
    end
  end
  return list
end

--! @brief quotes a string for literal usage in lua regex patterns
--! @param s string eg. lala[]
--! @param string eg. lala%[%]
function str.patternQuote (s)
	s = string.gsub(s, "([.$()%*+-?^])", "%%%1")
	s = string.gsub(s, "%[", "%%[")
	s = string.gsub(s, "%]", "%%]")
	return s
end

--! @brief Concat the contents of the parameter list,
--! separated by the string delimiter (just like in perl)
--! example: str.join(", ", {"Anna", "Bob", "Charlie", "Dolores"})
--! @param delimiter string
--! @param list table
--! @param string glued stringparts
function str.join(delimiter, list) 
	return table.concat(list,delimiter) 
end

--! @brief concats table values
--! old, slow, but can handle associative tables rather than just arrays
--! @see str.join
--! @param delimiter string
--! @param list table
--! @param string glued stringparts
function str.join_assoc(delimiter, list) -- 
	local res = ""
	local bFirst = true
	for k,v in pairs(list) do 
		if (bFirst) then 
				res = tostring(v) bFirst = false 
		else	res = res .. delimiter .. tostring(v) 
		end
	end
	return res
end


--! @brief removed newlines from the end of the string
--! @param line string
--! @param string
function str.trimNewLines (line)
	if (string.sub(line, -1) == "\n" or string.sub(line, -1) == "\r") then line = string.sub(line,1,string.len(line)-1) end
	if (string.sub(line, -1) == "\n" or string.sub(line, -1) == "\r") then line = string.sub(line,1,string.len(line)-1) end
	return line
end

--! @brief reduces the unicode string (an array with charcodes) to an ascii string, using ? for non-asci chars. keeps length
--! useful for parsing, e.g iris widget.uotext.lua 
--! @param unicode_string string
--! @return string
function str.unicodeToPlainText_KeepLength (unicode_string)
	local plaintext = ""
	for k,unicode_charcode in ipairs(unicode_string) do 
		plaintext = plaintext .. (	(unicode_charcode >= 32 and unicode_charcode < 127) and 
									string.format("%c",unicode_charcode) or "?") -- non-asci specifics are lost
	end
	assert(#plaintext == #unicode_string,"UnicodeToPlainText_KeepLength failed")
	return plaintext
end


--! @brief reduces stringlength to maxlen if neccessary
--! @param str string
--! @return string
function str.maxLen (str,maxlen)
	local len = string.len(str)
	if len < maxlen then return str end
	return string.sub(str,1,maxlen)
end

--! @brief checks if the given strings starts with begin
--! @param s string
--! @param begin string prefix to check
--! @return bool
function str.beginswith (s,begin) 
	return string.sub(s,1,string.len(begin)) == begin 
end

--! @brief some letters from the left
--! @param str string complete string
--! @param int number of letters
--! @return string part from left
function str.left  (str,len) 
	return string.sub(str,1,len) 
end

--! @brief some letters from the right
--! @param str string complete string
--! @param int number of letters
--! @return string part from right
function str.right (str,len) 
	return string.sub(str,-len) 
end

--! @brief search needle in haystack
--! @param haystack string
--! @param needle string
--! @return bool true if needle is in haystack
function str.contains (haystack,needle) 
	return (string.find(haystack,needle,1,true)) ~= nil 
end



--! @brief returns a new string without the non visible chars at the beginning and end
--! @param s string
--! @param pattern lua pattern OPTIONAL
--! @return string
function str.trim (s, pattern)
	pattern = pattern or "%c%s"
	-- %c controll chars, %s space chars
	return string.gsub(string.gsub(s,"["..pattern.."]*$",""),"^["..pattern.."]*","")
end

--! @brief adds spaces to the left
--! @param s string
--! @param minlen int number of spaces to add from left
--! @return string
function str.pad(s,minlen) 
	s = tostring(s) 
	local padlen = minlen-#s 
	if (padlen > 0) then 
		return s .. string.rep(" ",padlen) 
	end 
	
	return s 
end

return str
