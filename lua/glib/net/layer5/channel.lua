local self = {}
GLib.Net.Layer5.Channel = GLib.MakeConstructor (self)

function self:ctor (channelName, handler)
	self.Name    = channelName
	self.Handler = handler or GLib.NullCallback
end

function self:DispatchPacket (destinationId, packet)
	GLib.Error ("Layer5.Channel:DispatchPacket : Not implemented.")
end

function self:GetHandler ()
	return self.Handler
end

function self:GetMTU ()
	GLib.Error ("Layer5.Channel:GetMTU : Not implemented.")
end

function self:GetName ()
	return self.Name
end

function self:SetHandler (handler)
	self.Handler = handler
	return self
end