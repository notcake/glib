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
	-- Identity
	self.InnerChannel = innerChannel
	
	self.SingleEndpointChannels = {}
	
	self.InnerChannel:SetHandler (
		function (sourceId, inBuffer)
			if not self.SingleEndpointChannels [sourceId] then
				self:CreateSingleEndpointChannel (sourceId)
			end
			self.SingleEndpointChannels [sourceId]:HandlePacket (inBuffer)
		end
	)
	
	GLib.PlayerMonitor:AddEventListener ("PlayerDisconnected", "OrderedChannel." .. self:GetName (),
		function (_, ply, userId)
			if not self.SingleEndpointChannels [userId] then return end
			
			self.SingleEndpointChannels [userId]:dtor ()
			self.SingleEndpointChannels [userId] = nil
		end
	)
	
	self:AddEventListener ("NameChanged",
		function (_, oldName, name)
			for _, singleEndpointOrderedChannel in pairs (self.SingleEndpointChannels) do
				singleEndpointOrderedChannel:SetName (name)
			end
		end
	)
	
	self:Register ()
end

function self:dtor ()
	for _, singleEndpointChannel in pairs (self.SingleEndpointChannels) do
		singleEndpointChannel:dtor ()
	end
	
	GLib.PlayerMonitor:RemoveEventListener ("PlayerDisconnected", "OrderedChannel." .. self:GetName ())
	
	self:Unregister ()
end

function self:GetInnerChannel ()
	return self.InnerChannel
end

-- Registration
function self:Register ()
	if self:IsRegistered () then return end
	
	GLib.Net.Layer5.RegisterChannel (self)
	self:SetRegistered (true)
end

function self:Unregister ()
	if not self:IsRegistered () then return end
	
	GLib.Net.Layer5.UnregisterChannel (self)
	self:SetRegistered (false)
end

-- State
function self:IsOpen ()
	return self.InnerChannel:IsOpen ()
end

function self:SetOpen (open)
	self.InnerChannel:SetOpen (open)
	return self
end

-- Packets
function self:DispatchPacket (destinationId, packet)
	if not self.SingleEndpointChannels [destinationId] then
		self:CreateSingleEndpointChannel (destinationId)
	end
	return self.SingleEndpointChannels [destinationId]:DispatchPacket (packet)
end

function self:GetMTU ()
	return self.InnerChannel:GetMTU () - 4
end

-- Handlers
function self:SetHandler (handler)
	if self.Handler == handler then return self end
	
	self.Handler = handler
	
	-- Update handlers for SingleEndpointOrderedChannels
	for _, singleEndpointOrderedChannel in pairs (self.SingleEndpointChannels) do
		singleEndpointOrderedChannel:SetHandler (handler)
	end
	
	return self
end

-- Internal, do not call
function self:CreateSingleEndpointChannel (remoteId)
	if self.SingleEndpointChannels [remoteId] then return self.SingleEndpointChannels [remoteId] end
	
	local singleEndpointChannel = GLib.Net.SingleEndpointChannel (self:GetInnerChannel (), remoteId)
	local singleEndpointOrderedChannel = GLib.Net.Layer5.SingleEndpointOrderedChannel (singleEndpointChannel)
	self.SingleEndpointChannels [remoteId] = singleEndpointOrderedChannel
	singleEndpointOrderedChannel:SetName (self:GetName ())
	singleEndpointOrderedChannel:SetHandler (self:GetHandler ())
	
	return self.SingleEndpointChannels [remoteId]
end