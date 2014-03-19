local self = {}
GLib.Net.Layer1.Channel = GLib.MakeConstructor (self)

function self:ctor (channelName, handler)
	self.Name    = channelName
	self.Handler = handler or GLib.NullCallback
	
	self.Open = false
end

function self:DispatchPacket (destinationid, packet)
	GLib.Error ("Layer1.Channel:DispatchPacket : Not implemented.")
end

function self:GetHandler ()
	return self.Handler
end

function self:GetMTU ()
	GLib.Error ("Layer1.Channel:GetMTU : Not implemented.")
end

function self:GetName ()
	return self.Name
end

function self:IsOpen (destinationId)
	return self.Open
end

function self:SetHandler (handler)
	self.Handler = handler
	return self
end

function self:SetOpen (open)
	self.Open = open
	return self
end