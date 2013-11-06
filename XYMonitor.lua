-- XYMonitor

XYMonitor = Class:extend
{
	obj = nil,
	oldX = nil,
	oldY = nil,
	threshold = 0.1,
	
	-- fun(oldx,oldy,newx,newy)
	onChangeFunction = nil,
	
	onNew = function (self)
		local obj = self.obj
		if not obj then return end
		self.oldX = obj.x
		self.oldY = obj.y
	end,
	
	checkAndCall = function (self)
		local obj = self.obj
		if not obj then return end
		--~ print(self.oldX, self.oldY, obj.x, obj.y)
		if math.abs(obj.x - self.oldX) > self.threshold or math.abs(obj.y - self.oldY) > self.threshold then
			self.onChangeFunction(self.oldX, self.oldY, obj.x, obj.y)
			self.oldX = obj.x
			self.oldY = obj.y
		end
	end,
}
