local self = {}
GLib.Net.Layer5.ConnectionChannel = GLib.MakeConstructor (self)

function self:ctor (channelName, handler, channel)
	self.Channel = channel
	
	self.Connections = {}
end

function self:Connect (destinationId, packet)
	
end