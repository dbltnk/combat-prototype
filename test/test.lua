
-- returns part, new_buffer
function pop_part_from_buffer (buffer)
	if buffer == nil or string.len(buffer) == 0 then return nil, buffer end
	local p = string.find(buffer, "\n", 1, true)
	if p then
		local part = string.sub(buffer, 1, p)
		local rest = string.sub(buffer, p + 1)
		if string.len(rest) == 0 then rest = nil end
		return part, rest
	else
		return nil, buffer
	end
end

local part, buffer = nil, "{'levelCap':10,'oid':15,'class':'Character','cmd':'create','image':'/assets/graphics/npc.png','currentEnergy':300,'level':0,'xpCap':1000,'owner':1,'xp':0,'width':64,'y':2859,'x':2132,'channel':'game','height':64,'maxEnergy':300,'rotation':0,'currentPain':0}\n{'levelCap':10,'oid':16,'class':'Character','cmd':'create','image':'/assets/graphics/npc.png','currentEnergy':300,'level':0,'xpCap':1000,'owner':1,'xp':0,'width':64,'y':2783,'x':2547,'channel':'game','height':64,'maxEnergy':300,'rotation':0,'currentPain':0}\n"

--~ buffer = "{1,2,3}\n[a,b,v]\n"

while true do
	part, buffer = pop_part_from_buffer(buffer)
	print(part)
	print("-----------------------")
	print(buffer)
	print("#######################")
	if not part or not buffer then break end
end
