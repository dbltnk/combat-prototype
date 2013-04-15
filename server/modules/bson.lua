--
-- Pure Lua (5.1) implementation of BSON
--
--
-- Copyright (c) 2013, Todd Coram. All rights reserved.
-- See LICENSE for details.
--

local string = require 'string'
local math = require 'math'

local bson = {}

-- Helper functions

local function toLSB(bytes,value)
  local res = ''
  local size = bytes
  local str = ""
  for j=1,size do
     str = str .. string.char(value % 256)
     value = math.floor(value / 256)
  end
  return str
end

local function toLSB32(value) return toLSB(4,value) end
local function toLSB64(value) return toLSB(8,value) end

local function fromLSB32(s)
   return s:byte(1) + (s:byte(2)*256) + 
      (s:byte(3)*65536) + (s:byte(4)*16777216)
end

local function fromLSB64(s)
   return fromLSB32(s) +
      (s:byte(5)*4294967296) + (s:byte(6)*1099511627776) +
      (s:byte(7)*2.8147497671066e+14) + (s:byte(8)*7.2057594037928e+16)
end


-- BSON generators
--

-- TODO number special case: Infinity
-- TODO number special case: Not A Number (NaN)

function bson.to_bool(n,v) 
   local pre = "\008"..n.."\000"
   if v then
      return pre.."\001"
   else
      return pre.."\000"
   end
end

function strToBin(s)
	local len = string.len(s)
	local result = ""
	for i = 1,len do
		--~ print("*", i, s:byte(i), numToBin(s:byte(i), 7, 8))
		result = result .. numToBin(s:byte(i), 7, 8)
	end
	--~ print("strToBin", s, "->", result)
	return result
end

function binToStr(b)
	local len = string.len(b)
	local result = ""
	for i = 1, len, 8 do
		local c = binToNum(b:sub(i,i+8-1), 7)
		result = result .. string.char(c)
		--~ print("binToStr", i,len,result, b:sub(i,i+8-1), c)
	end
	--~ print("binToStr", b, "->", result)
	return result
end

function binToNum(b, startIndex)
	local x = 2^startIndex
	local result = 0
	local len = string.len(b)
	for i = 1, len do
		--~ print(i,b:sub(i,i),x)
		if b:sub(i,i) == "1" then result = result + x end
		x = x / 2
	end
	--~ print("+++", "binToNum", b, startIndex, result)
	return result
end

function numToBin(x, startIndex, bits)
	--~ print("-------- numToBin",x,bits,startIndex)
	local b = 2^startIndex
	local result = ""
	for i = startIndex, startIndex - bits + 1, -1 do
		if b <= x then 
			x = x - b 
			result = result .. "1"
		else
			result = result .. "0"
		end
		--~ print(i, x, b, result)
		b = b / 2
	end
	return result
end

-- returns sign, exponent, fraction
function toIEEE754(v)
	local x = math.abs(v)
	local sign = v < 0 and 1 or 0
	local startIndex = math.floor(math.log(x) / math.log(2))
	local startX = 2^startIndex
	--~ print(sign, startIndex, startX, x / startX)
	
	local result
	
	-- special cases
	if v == 0 then
		-- 0
		result = "00000000000000000000000000000000000000000000000000000"
	else
		result = "" .. sign .. numToBin(startIndex + 1023, 10, 11) .. 
			numToBin(x / startX, 0, 53):sub(2)
	end
	
	return result
end

function fromIEEE754(b)
	local sign = b:sub(1,1) == "1" and -1 or 1
	local exponentBits = b:sub(2,2+10)
	
	local exponent, significant
	
	-- 0. special case
	if exponentBits == "00000000000" then
		exponent = 0
		significant = binToNum("0" .. b:sub(13), 0)
	else
		exponent = binToNum(exponentBits, 10) - 1023
		significant = binToNum("1" .. b:sub(13), 0)
	end
	
	--~ print("SIGN", sign, "EXP", exponent, "SIG", significant)
		
	-- special cases
	-- 0
	if b == "00000000000000000000000000000000000000000000000000000" then
		return 0
	else
		return sign * significant * 2^exponent
	end
end

--[[
function test(expected, was, text)
	if expected ~= was then
		print("----- failed", text, "------------------------------------------------------------------")
		print(" - expected", type(expected), expected)
		print(" -      was", type(was), was)
		os.exit(1)
	else
		print("----- ok", text, "--------------------------------------------------------------------")
	end
end

test("11010010010000000000000000000000000000000000000000000", numToBin(1.6425781250000000, 0, 53), "0")
test("1100000001101010010010000000000000000000000000000000000000000000", toIEEE754(-210.25), "1")
test(-210.25, fromIEEE754("1100000001101010010010000000000000000000000000000000000000000000"), "2")
test(1030, binToNum("10000000110", 10), "3")
test(169, binToNum("10101001", 7), "byte")
test(1.6425781250000000, binToNum("11010010010000000000000000000000000000000000000000000", 0), "4")
test(0, fromIEEE754(toIEEE754(0)), "x = 0")
test("1011111111110000000000000000000000000000000000000000000000000000", toIEEE754(-1), "x = -1 BIB")
test(-1, fromIEEE754(toIEEE754(-1)), "x = -1")
test(1, fromIEEE754(toIEEE754(1)), "x = 1")
test(8, string.len(binToStr(toIEEE754(1.2345))), "len")
for i = 1,10 do
	local x = math.random() * 10000
	test(x, fromIEEE754(strToBin(binToStr(toIEEE754(x)))), "x = " .. x)
end
test("01101010", numToBin(106, 7, 8), "#########")
test("1111111011100011110000001000001110010000110111001001011110001101", 
	strToBin(binToStr("1111111011100011110000001000001110010000110111001001011110001101")), "bin2str2bin")
test(1.2345, fromIEEE754(strToBin(binToStr(toIEEE754(1.2345)))), "1.2345")
--~ os.exit()
]]

function bson.to_double(n,v) 
   local pre = "\001"..n.."\000"
   local s = binToStr(toIEEE754(v))
   --~ print("#### TO DOUBLE1", toIEEE754(v))
   --~ print("#### TO DOUBLE2", toIEEE754(-210.25))
   return pre..s
end

function bson.to_str(n,v) return "\002"..n.."\000"..toLSB32(#v+1)..v.."\000" end
function bson.to_int32(n,v) return "\016"..n.."\000"..toLSB32(v) end
function bson.to_int64(n,v) return "\018"..n.."\000"..toLSB64(v) end
function bson.to_x(n,v) return v(n) end

function bson.utc_datetime(t)
   local t = t or (os.time()*1000)
   f = function (n)
      return "\009"..n.."\000"..toLSB64(t)
   end
   return f
end

-- Binary subtypes
bson.B_GENERIC  = "\000"
bson.B_FUNCTION = "\001"
bson.B_UUID     = "\004"
bson.B_MD5      = "\005"
bson.B_USER_DEFINED = "\128"

function bson.binary(v, subtype)
   local subtype = subtype or bson.B_GENERIC
   f = function (n) 
      return "\005"..n.."\000"..toLSB32(#v)..subtype..v
   end
   return f
end

function bson.to_num(n,v)
	-- TODO negative ints are broken so
 	-- just use floats in this case
   if math.floor(v) ~= v or v < 0 then
      return bson.to_double(n,v)
   elseif v > 2147483647 or v < -2147483648 then
      return bson.to_int64(n,v)
   else
      return bson.to_int32(n,v)
   end
end

function bson.to_doc(n,doc)
   local d=bson.start()
   local doctype = "\003"
   for cnt,v in ipairs(doc) do
      local t = type(v)
      local o = lua_to_bson_tbl[t](tostring(cnt-1),v)
      d = d..o
      doctype = "\004"
   end
   -- do this only if we don't have an array (enumerated pairs)
   if d == "" then
      for nm,v in pairs(doc) do
	 local t = type(v)
	 local o = lua_to_bson_tbl[t](nm,v)
	 d = d..o
      end
   end
   return doctype..n.."\000"..bson.finish(d)
end


-- Mappings between lua and BSON.
-- "function" is a special catchall for non-direct mappings.
--
lua_to_bson_tbl= {
   boolean = bson.to_bool,
   string = bson.to_str,
   number = bson.to_num,
   table = bson.to_doc,
   ["function"] = bson.to_x
}

-- BSON document creation.
--
function bson.start() return "" end

function bson.finish(doc) 
   doc = doc .. "\000"
   return toLSB32(#doc+4)..doc
end

function bson.encode(doc)
   local d=bson.start()
   for e,v in pairs(doc) do
      local t = type(v)
      local o = lua_to_bson_tbl[t](e,v)
      d = d..o
   end
   return bson.finish(d)
end


-- BSON parsers

function bson.from_bool(s)
   return s:byte(1) == 1, s:sub(2)
end

function bson.from_double(s)
	--~ print("#### FR DOUBLE", strToBin(s:sub(1,8)))
	return fromIEEE754(strToBin(s:sub(1,8))), s:sub(9)
end

function bson.from_int32(s)
   return fromLSB32(s:sub(1,4)), s:sub(5)
end

function bson.from_int64(s)
   return fromLSB64(s:sub(1,8)), s:sub(9)
end

function bson.from_utc_date_time(s)
   return fromLSB64(s:sub(1,8)), s:sub(9)
end

function bson.from_binary(s)
   local len = fromLSB32(s:sub(1,4))
   s = s:sub(6)
   local str = s:sub(1,len-1)
   return str, s:sub(len+1)
end


function bson.from_str(s)
   local len = fromLSB32(s:sub(1,4))
   s = s:sub(5)
   local str = s:sub(1,len-1)
   return str, s:sub(len+1)
end

function replaceNonPrintableChars(s, replacement)
	local r = ""
	for i = 1,string.len(s) do
		local b = s:byte(i)
		if b >= 33 and b <= 126 then r = r .. string.char(b)
		else r = r .. replacement end
	end
	return r
end

function toHex(s)
	if not s or type(s) ~= "string" then return "<nil>" end
	
	local r = ""
	for i = 1,string.len(s) do
		r = r .. (s:byte(i) < 16 and "0" or "") .. string.format("%x ", s:byte(i))
	end
	r = r .. "(" .. string.len(s) .. " bytes) [" .. replaceNonPrintableChars(s, ".") .. "]"
	return r
end

function bson.decode_doc(doc,doctype)
   --~ print("decode_doc", doctype, toHex(doc))
   local luatab = {}
   local len = fromLSB32(doc:sub(1,4))
   doc=doc:sub(5)
   repeat
      local val
      local etype = doc:byte(1)
      --~ print("etype", etype)
      if etype == 0 then doc=doc:sub(2) break end
      local ename = doc:match("(%Z+)\000",2)
      doc = doc:sub(#ename+3)
      --~ print("decode_doc_sub", ename, etype, toHex(doc))
      val,doc = bson_to_lua_tbl[etype](doc,etype)
      --~ print("decode_doc_val", val, toHex(doc))
      if doctype == 4 then
		-- replaces this line because luvit blocks executing table.insert ?????
		--~ table.insert(luatab,val)
		luatab[#luatab + 1] = val
      else
		luatab[ename] = val
      end
      --~ print("DOC LEFT", toHex(doc))
   until not doc
   return luatab,doc
end

bson_to_lua_tbl= {
   [1] = bson.from_double,
   [2] = bson.from_str,
   [16] = bson.from_int32,
   [18] = bson.from_int64,
   [8] = bson.from_bool,
   [3] = bson.decode_doc,
   [4] = bson.decode_doc,
   [5] = bson.from_binary,
   [9] = bson.from_utc_date_time
}

function bson.decode(doc)
	if string.len(doc) < 4 then return nil, doc end
	local len = fromLSB32(doc:sub(1,4))
	print(len, doc:len(), toHex(doc))
	if string.len(doc) < len then return nil, doc end
	subdoc=doc:sub(1, len)
	a,d=bson.decode_doc(subdoc,nil)
	return a,doc:sub(len + 1)
end

function bson.decode_next_io(fd)
   local slen = fd:read(4)
   if not slen then return nil end
   local len = fromLSB32(slen) - 4
   local doc = fd:read(len)
   return bson.decode(slen..doc)
end


return bson
