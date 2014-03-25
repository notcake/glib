local self = {}
GLib.Net.Layer3.Layer2Channel = GLib.MakeConstructor (self, GLib.Net.Layer3.Channel)

function GLib.Net.Layer3.Layer2Channel.ctor (channelName, handler, innerChannel)
	if type (channelName) ~= "string" then
		innerChannel = channelName
		channelName  = innerChannel:GetName ()
	end
	
	innerChannel = innerChannel or GLib.Net.Layer2.GetChannel (channelName)
	innerChannel = innerChannel or GLib.Net.Layer2.RegisterChannel (channelName)
	
	return GLib.Net.Layer3.Layer2Channel.__ictor (channelName, handler, innerChannel)
end

function self:ctor (channelName, handler, innerChannel)
	self.InnerChannel = innerChannel
	self.InnerChannel:SetHandler (handler)
	
	GLib.Net.Layer3.RegisterChannel (self)
end

function self:dtor ()
	self.InnerChannel:dtor ()
	
	GLib.Net.Layer3.UnregisterChannel (self)
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