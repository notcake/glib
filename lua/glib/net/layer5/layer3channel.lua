local self = {}
GLib.Net.Layer5.Layer3Channel = GLib.MakeConstructor (self, GLib.Net.Layer5.Channel)

function GLib.Net.Layer5.Layer3Channel.ctor (channelName, handler, innerChannel)
	if type (channelName) ~= "string" then
		innerChannel = channelName
		channelName  = innerChannel:GetName ()
	end
	
	innerChannel = innerChannel or GLib.Net.Layer3.GetChannel (channelName)
	innerChannel = innerChannel or GLib.Net.Layer3.RegisterChannel (channelName)
	
	return GLib.Net.Layer5.Layer3Channel.__ictor (channelName, handler, innerChannel)
end

function self:ctor (channelName, handler, innerChannel)
	self.InnerChannel = innerChannel
	self.InnerChannel:SetHandler (handler)
end

function self:DispatchPacket (destinationId, packet)
	return self.InnerChannel:DispatchPacket (destinationId, packet)
end

function self:GetHandler ()
	return self.InnerChannel:GetHandler ()
end

function self:GetMTU ()
	return self.InnerChannel:GetMTU ()
end

function self:IsOpen ()
	return self.InnerChannel:IsOpen ()
end

function self:SetHandler (handler)
	self.InnerChannel:SetHandler (handler)
	self.Handler = handler
	return self
end

function self:SetOpen (open)
	self.InnerChannel:SetOpen (open)
	return self
end