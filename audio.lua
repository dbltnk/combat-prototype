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

	audio.peaceMusic = playSound('/assets/audio/eots.ogg', config.volume, 'long') -- Shadowbane Soundtrack: Eye of the Storm
	audio.peaceMusic:setLooping(true)

	audio.combatMusic = playSound('/assets/audio/dos.ogg', 0, 'long') -- Shadowbane Soundtrack: Dance of Steel
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
