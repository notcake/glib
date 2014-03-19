local self = {}
GLib.Net.Layer2.Channel = GLib.MakeConstructor (self)

function self:ctor (channelName, handler)
	self.Name    = channelName
	self.Handler = handler or GLib.NullCallback
	
	self.Open = false
end

function self:DispatchPacket (destinationId, packet)
	GLib.Error ("Layer2.Channel:DispatchPacket : Not implemented.")
end

function self:GetHandler ()
	return self.Handler
end

function self:GetName ()
	return self.Name
end

function self:IsOpen (destinationId)
	return self.Open
end

function self:SetOpen (open)
	self.Open = open
	return self
end

function self:SetHandler (handler)
	self.Handler = handler
	return self
end