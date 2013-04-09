-- audio

audio = {}

-- combat music fade in/out 		
audio.fadeTime = 3

audio.loudness_is_fading = false
audio.loudness = config.volume

audio.isInCombat = false

audio.peaceMusic = nil
audio.combatMusic = nil

function audio.init()

	audio.peaceMusic = playSound('/assets/audio/peace.ogg', config.volume, 'long')
	audio.peaceMusic:setLooping(true)

	audio.combatMusic = playSound('/assets/audio/war.ogg', 0, 'long')
	audio.combatMusic:setLooping(true)
	
end

function audio.update()
	local newLoundness = (audio.isInCombat and 0) or 1

	-- not fading and wrong loudness?
	if audio.loudness_is_fading == false and math.abs(newLoundness - audio.loudness) > 0.01 then
		-- start fade
		audio.loudness_is_fading = true
		the.app.view.tween:start(audio, "loudness", newLoundness, audio.fadeTime)
			:andThen(function() audio.loudness_is_fading = false end)
	end

	audio.peaceMusic:setVolume(audio.loudness)
	audio.combatMusic:setVolume(1 - audio.loudness)
end




		
return audio
