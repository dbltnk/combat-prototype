-- ConnectView

ConnectView = View:extend
{
	onNew = function (self)
		
    end,
    
    onUpdate = function (self, elapsed)
		if network.client_id then
			self:die()
			the.app.view = GameView:new()
		end
    end,
}

