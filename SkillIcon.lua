-- SkillIcon

SkillIcon = Animation:extend
{
	width = 32,
	height = 32,
	image = "/assets/graphics/action_icons/unknown.png",
	color = {1,1,1},
	sequences = 
	{
		available = { frames = {1}, fps = 1 },
		casting = { frames = {1}, fps = 1 },
		disabled = { frames = {1}, fps = 1 },
	},
	
	onNew = function (self)
		
	end,
	
	setSkill = function (self, image)
		self.image = image
	end,
	
	onUpdate = function (self)
		self.tint = self.color
	end
}
