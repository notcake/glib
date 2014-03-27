local self = {}
GLib.Networking.Networkable = GLib.MakeConstructor (self)

--[[
	Events:
		DispatchPacket (destinationId, OutBuffer packet)
			Fired when a packet needs to be dispatched.
]]

function self:ctor ()
	-- Subscribers
	self.SubscriberSet = nil
end

-- Subscribers
function self:GetSubscriberSet ()
	return self.SubscriberSet
end

function self:SetSubscriberSet (subscriberSet)
	if self.SubscriberSet == subscriberSet then return self end
	
	self.SubscriberSet = subscriberSet
	
	return self
end

-- Packets
function self:DispatchPacket (destinationId, packet)
	destinationId = destinationId or self.SubscriberSet
	
	self:DispatchEvent ("DispatchPacket", destinationId, packet)
end

function self:HandlePacket (sourceId, inBuffer)
end