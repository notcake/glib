local self = {}
GLib.Net.Layer5.Layer3Channel = GLib.MakeConstructor (self)

function GLib.Net.Layer5.Layer3Channel.ctor (channelName, handler, channel)
	if type (channelName) ~= "string" then
		channel     = channelName
		channelName = channel:GetName ()
	end
	
	channel = channel or GLib.Net.Layer3.GetChannel (channelName)
	channel = channel or GLib.Net.Layer3.RegisterChannel (channelName)
	
	return GLib.Net.Layer5.Layer3Channel.__ictor (channelName, handler, channel)
end

function self:ctor (channelName, handler, channel)
	self.Channel = channel
	self.Channel:SetHandler (handler)
end

function self:DispatchPacket (destinationId, packet)
	return self.Channel:DispatchPacket (destinationId, packet)
end

function self:GetHandler ()
	return self.Channel:GetHandler ()
end

function self:GetMTU ()
	return self.Channel:GetMTU ()
end

function self:SetHandler (handler)
	self.Channel:SetHandler (handler)
	self.Handler = handler
	return self
end