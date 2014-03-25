local self = {}
GLib.Net.Layer5.OrderedChannel = GLib.MakeConstructor (self, GLib.Net.Layer5.Channel)

function GLib.Net.Layer5.OrderedChannel.ctor (channelName, handler, innerChannel)
	if type (channelName) ~= "string" then
		innerChannel = channelName
		channelName  = innerChannel:GetName ()
	end
	
	innerChannel = innerChannel or GLib.Net.Layer3.GetChannel (channelName)
	innerChannel = innerChannel or GLib.Net.Layer3.RegisterChannel (channelName)
	
	return GLib.Net.Layer5.OrderedChannel.__ictor (channelName, handler, innerChannel)
end

function self:ctor (channelName, handler, innerChannel)
	self.InnerChannel = innerChannel
	
	self.Instances = {}
	
	self.InnerChannel:SetHandler (
		function (sourceId, inBuffer)
			self.Instances [sourceId] = self.Instances [sourceId] or GLib.Net.Layer5.OrderedChannelInstance (self, sourceId)
			self.Instances [sourceId]:HandlePacket (inBuffer)
		end
	)
	
	GLib.PlayerMonitor:AddEventListener ("PlayerDisconnected", "OrderedChannel." .. self:GetName (),
		function (_, ply, userId)
			if not self.Instances [userId] then return end
			
			self.Instances [userId]:dtor ()
			self.Instances [userId] = nil
		end
	)
	
	GLib.Net.Layer5.RegisterChannel (self)
end

function self:dtor ()
	GLib.PlayerMonitor:RemoveEventListener ("PlayerDisconnected", "OrderedChannel." .. self:GetName ())
	
	self.InnerChannel:dtor ()
	
	GLib.Net.Layer5.UnregisterChannel (self)
end

function self:DispatchPacket (destinationId, packet)
	self.Instances [destinationId] = self.Instances [destinationId] or GLib.Net.Layer5.OrderedChannelInstance (self, destinationId)
	return self.Instances [destinationId]:DispatchPacket (packet)
end

function self:GetInnerChannel ()
	return self.InnerChannel
end

function self:GetMTU ()
	return self.InnerChannel:GetMTU () - 4
end

function self:IsOpen ()
	return self.InnerChannel:IsOpen ()
end

function self:SetOpen (open)
	self.InnerChannel:SetOpen (open)
	return self
end