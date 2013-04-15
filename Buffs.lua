-- Buff

Buff = Class:extend
{
  startTime = nil,
  endTime = nil,
  startValue = nil,
  endValue = nil,
  name = nil,
  -- name of the buffed variable
  property = nil,
  -- tag -> true map
  tags = {},
  sourceOid = nil,
  
  onNew = function (self)
    
  end,
  
  apply = function (self, t, obj)
    local v = 0
    if self.endTime == nil then
      -- unlimited
      v = self.startValue
    else
      v = utils.mapIntoRange(t, self.startTime, self.endTime, self.startValue, self.endValue)
    end
    
    obj[self.property] = (obj[self.property] or 0) + v
  end,
  
  -- returns 0-1
  percentageDone = function (self)
    if self.endTime == nil then
      -- unlimited
      return 0
    else
      return utils.mapIntoRange(t, self.startTime, self.endTime, 0, 1)
    end
  end,
}

-- Buffs

Buffs = Class:extend
{
  buffs = {},
  
	onNew = function (self)
  
  end,
  
  -- iterator: index,buff
  enumAll = function (self)
    return coroutine.wrap(function () 
      for k,buff in pairs(self.buffs) do
        coroutine.yield(k,buff)
      end
    end)
  end,
  
  -- iterator: index,buff
  enumByTag = function (self, tag)
    return coroutine.wrap(function () 
      for k,buff in pairs(self.buffs) do
        if buff.tags[tag] then
          coroutine.yield(k,buff)
        end
      end
    end)
  end,
  
  removeByTag = function (self, tag)
    for k,buff in self:enumByTag(tag) do
      self.buffs[k] = nil
    end
  end,
  
  removeAll = function (self)
    self.buffs = {}
  end,
}

--[[
local b = Buffs:new()
table.insert(b.buffs, Buff:new{
    name = "b1",
  })
table.insert(b.buffs, Buff:new{
    name = "lala",
    tags = { lala = true, blub = true, },
  })

for i,b in b:enumByTag("lala") do
  print(i,b.name)
end

os.exit()
]]
