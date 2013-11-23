
function getTeamColor(name)
	if config.teamColors[name] then
		return config.teamColors[name]
	else
		return {0,0,0}
	end	
end

