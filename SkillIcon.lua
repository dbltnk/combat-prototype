-- SkillIcon

SkillIcon = Animation:extend
{
	width = 32,
	height = 32,
	image = "/assets/graphics/action_icons/unknown.png",
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
}
