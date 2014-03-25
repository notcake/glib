local self = {}
GLib.Net.ISingleEndpointChannel = GLib.MakeConstructor (self)

--[[
	Events:
		NameChanged (oldName, name)
			Fired when this channel's name has been changed.
]]

function self:ctor (channelName, handler)
	-- Identity
	self.Name     = channelName
	self.RemoteId = nil
	
	-- State
	self.Open = false
	
	-- Handlers
	self.Handler  = handler or GLib.NullCallback
	
	GLib.EventProvider (self)
end

-- Identity
function self:GetName ()
	return self.Name
end

function self:GetRemoteId ()
	return self.RemoteId
end

function self:SetName (name)
	if self.Name == name then return self end
	
	local lastName = self.Name
	self.Name = name
	self:DispatchEvent ("NameChanged", lastName, self.Name)
	
	return self
end

-- State
function self:IsOpen (destinationId)
	return self.Open
end

function self:SetOpen (open)
	self.Open = open
	return self
end

-- Packets
function self:DispatchPacket (packet)
	GLib.Error ("ISingleEndpointChannel:DispatchPacket : Not implemented.")
end

function self:GetMTU ()
	GLib.Error ("ISingleEndpointChannel:GetMTU : Not implemented.")
end

-- Handlers
function self:GetHandler ()
	return self.Handler
end

function self:SetHandler (handler)
	self.Handler = handler
	return self
end