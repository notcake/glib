local self = {}
GLib.Net.Layer3.Layer2Channel = GLib.MakeConstructor (self, GLib.Net.Layer3.Channel)

function GLib.Net.Layer3.Layer2Channel.ctor (channelName, handler, channel)
	if type (channelName) ~= "string" then
		channel     = channelName
		channelName = channel:GetName ()
	end
	
	channel = channel or GLib.Net.Layer2.GetChannel (channelName)
	channel = channel or GLib.Net.Layer2.RegisterChannel (channelName)
	
	return GLib.Net.Layer3.Layer2Channel.__ictor (channelName, handler, channel)
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

function self:IsOpen ()
	return self.Channel:IsOpen ()
end

function self:SetHandler (handler)
	self.Channel:SetHandler (handler)
	self.Handler = handler
	return self
end

function self:SetOpen (open)
	self.Channel:SetOpen (open)
	return self
end