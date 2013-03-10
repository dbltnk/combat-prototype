-- SyncedObject

SyncedObject = Tile:extend
{
	width = 32,
	height = 32,
	image = '/assets/graphics/unknown_object.png',
	oid = nil,
	owner = nil,
    	
	onUpdate = function (self)
	
	end,
	
	onDie = function (self)
		-- not possible to revive them later
		the.app.view.layers.characters:remove(self)
	end,
	
	onNew = function (self)
		the.app.view.layers.characters:add(self)
		drawDebugWrapper(self)
	end,
}
