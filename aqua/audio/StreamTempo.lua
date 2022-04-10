local bass = require("aqua.audio.bass")
local bass_fx = require("aqua.audio.bass_fx")
local Stream = require("aqua.audio.Stream")

local StreamTempo = Stream:new()

StreamTempo.construct = function(self)
	self.channelDecode = bass.BASS_StreamCreateFile(false, self.path, 0, 0, 0x220000)
	self.channel = bass_fx.BASS_FX_TempoCreate(self.channelDecode, 0x10000)
end

StreamTempo.free = function(self)
	bass.BASS_ChannelFree(self.channel)
	bass.BASS_ChannelFree(self.channelDecode)
end

StreamTempo.setRate = function(self, rate)
	if self.rateValue ~= rate then
		self.rateValue = rate
		return bass.BASS_ChannelSetAttribute(self.channel, 0x10000, (rate - 1) * 100)
	end
end

StreamTempo.setPitch = function(self, pitch)
	-- semitone 1 : 2^(1/12)
	if self.pitchValue ~= pitch then
		self.pitchValue = pitch
		return bass.BASS_ChannelSetAttribute(self.channel, 0x10001, 12 * math.log(pitch) / math.log(2))
	end
end

return StreamTempo
