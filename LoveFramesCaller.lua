-- LoveFramesCaller

LoveFramesCaller = Sprite:new
{
	class = "LoveFramesCaller",
	
	onNew = function (self)
		-- patch input methods
		
		local oldKeypressed = love.keypressed 
		local oldKeyreleased = love.keyreleased 
		local oldMousepressed = love.mousepressed 
		local oldMousereleased = love.mousereleased 

		love.textinput = function (text) loveframes.textpressed(text) end
		love.keypressed = function (key) oldKeypressed(key) loveframes.keypressed(key) end
		love.keyreleased = function (key) oldKeyreleased(key) loveframes.keyreleased(key) end

		love.mousepressed = function (x, y, button) oldMousepressed(x,y,button) loveframes.mousepressed(x, y, button) end
		love.mousereleased = function (x, y, button) oldMousereleased(x,y,button) loveframes.mousereleased(x, y, button) end
	end,

	onUpdate = function (self, elapsed)
		loveframes.update(elapsed)
    end,
    
	onDraw = function (self, x, y)
		loveframes.draw()
	end,
}
