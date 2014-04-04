local self = {}
GLib.Networking.NetworkableHost = GLib.MakeConstructor (self)

--[[
	Events:
		CustomPacketReceived (destinationId, InBuffer packet)
			Fired when a custom packet has been received.
		DispatchPacket (destinationId, OutBuffer packet)
			Fired when a packet needs to be dispatched.
]]

function self:ctor ()
	-- Channel
	self.Channel = nil
	
	-- Hosting
	self.HostId = nil
	
	-- Subscribers
	self.SubscriberSet = nil
	
	-- Networkables
	-- self.NextNetworkableId    = 1
	-- self.NetworkableIds       = GLib.WeakKeyTable ()
	-- self.NetworkablesById     = {}
	-- self.WeakNetworkablesById = GLib.WeakValueTable ()
	-- self.NetworkableRefCounts = {}
	self:ClearNetworkables () -- This will initialize the fields above
	
	-- Weak networkable checking
	self.WeakNetworkableCheckInterval = 5
	self.LastWeakNetworkableCheckTime = 0
end

function self:dtor ()
	self:ClearNetworkables ()
end

-- Channel
function self:GetChannel ()
	return self.Channel
end

function self:SetChannel (channel)
	if self.Channel == channel then return self end
	
	self.Channel = channel
	if self.Channel then
		self.Channel:SetHandler (
			function (sourceId, inBuffer)
				self:HandlePacket (sourceId, inBuffer)
			end
		)
	end
	
	return self
end

-- Hosting
function self:GetHostId ()
	return self.HostId
end

function self:IsHost (remoteId)
	return self.HostId == remoteId
end

function self:IsHosting (networkable)
	if networkable and networkable.IsHosting then
		if networkable:IsHosting () ~= nil then
			return networkable:IsHosting ()
		end
	end
	
	return self.HostId == GLib.GetLocalId ()
end

function self:SetHostId (hostId)
	if self.HostId == hostId then return self end
	
	self.HostId = hostId
	return self
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
function self:DispatchCustomPacket (destinationId, packet)
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:UInt8 (GLib.Networking.NetworkableHostMessageType.Custom)
	outBuffer:OutBuffer (packet)
	
	return self:DispatchPacket (destinationId, outBuffer)
end

function self:DispatchPacket (destinationId, packet, object)
	self:CheckWeakNetworkables ()
	
	destinationId = destinationId or self.SubscriberSet
	destinationId = destinationId or GLib.GetEveryoneId ()
	
	local networkableId = self:GetNetworkableId (object)
	if not object then networkableId = 0 end
	
	-- Build packet
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:UInt32 (networkableId)
	outBuffer:OutBuffer (packet)
	
	-- Dispatch
	if self.Channel then
		self.Channel:DispatchPacket (destinationId, outBuffer)
	else
		self:DispatchEvent ("DispatchPacket", destinationId, outBuffer)
	end
end

function self:HandlePacket (sourceId, inBuffer)
	self:CheckWeakNetworkables ()
	
	local networkableId = inBuffer:UInt32 ()
	if networkableId == 0 then
		-- Message destined for this NetworkableHost
		local messageType = inBuffer:UInt8 ()
		
		if messageType == GLib.Networking.NetworkableHostMessageType.NetworkableDestroyed then
			local networkableId = inBuffer:UInt32 ()
			if networkableId == 0 then return end -- Nope, we're not unregistering ourself
			self:UnregisterNetworkable (networkableId)
		elseif messageType == GLib.Networking.NetworkableHostMessageType.Custom then
			self:DispatchEvent ("CustomPacketReceived", sourceId, inBuffer)
		end
	else
		local networkable = self:GetNetworkable (networkableId)
		if not networkable then return end
		return networkable:HandlePacket (sourceId, inBuffer)
	end
end

-- Objects
function self:ClearNetworkables ()
	if self.NetworkableIds then
		for networkable, _ in pairs (self.NetworkableIds) do
			self:UnhookNetworkable (networkable)
		end
	end
	
	self.NextNetworkableId    = 1
	self.NetworkableIds       = GLib.WeakKeyTable ()
	self.NetworkablesById     = {}
	self.WeakNetworkablesById = GLib.WeakValueTable ()
	self.NetworkableRefCounts = {}
end

function self:GetNetworkableById (id)
	return self.NetworkablesById [id] or self.WeakNetworkablesById [id]
end

function self:GetNetworkableId (networkable)
	return self.NetworkableIds [networkable]
end

function self:IsNetworkableRegistered (networkable)
	return self.NetworkableIds [networkable] ~= nil
end

function self:RegisterNetworkable (networkable, networkableId)
	self:CheckWeakNetworkables ()
	
	if not self:IsHosting (networkable) and not networkableId then
		-- We're not the host so we shouldn't be allowed to register networkables
		GLib.Error ("NetworkableHost:RegisterNetworkable : Cannot register Networkables when not hosting!")
		return
	end
	if networkableId == 0 then
		-- Reserved ID, not allowed
		GLib.Error ("NetworkableHost:RegisterNetworkable : Cannot register Networkable with reserver ID 0!")
		return
	end
	
	if not self.NetworkableIds [networkable] then
		-- New networkable
		networkableId = networkableId or self:GenerateNetworkableId ()
		
		self.NetworkableIds [networkable] = networkableId
		self.NetworkableRefCounts [networkableId] = 0
		
		if self:IsHosting (networkable) then
			self.WeakNetworkablesById [networkableId] = networkable
		else
			self.NetworkablesById [networkableId] = networkable
		end
		
		networkable:SetNetworkableHost (self)
		
		-- Hook networkable
		self:HookNetworkable (networkable)
	else
		networkableId = self.NetworkableIds [networkable]
	end
	
	self.NetworkableRefCounts [networkableId] = self.NetworkableRefCounts [networkableId] + 1
end

function self:UnregisterNetworkable (networkableOrNetworkableId)
	local networkable
	local networkableId
	if type (networkableOrNetworkableId) == "number" then
		networkableId = networkableOrNetworkableId
		networkable = self:GetNetworkableById (networkableId)
	else
		networkable = networkableOrNetworkableId
		networkableId = self:GetNetworkableId (networkable)
	end
	
	if not networkable   then return end
	if not networkableId then return end
	
	self.NetworkableRefCounts [networkableId] = self.NetworkableRefCounts [networkableId] - 1
	
	if self.NetworkableRefCounts [networkableId] == 0 then
		self.NetworkableIds [networkable] = nil
		self.NetworkablesById [networkableId] = nil
		self.WeakNetworkablesById [networkableId] = nil
		self.NetworkableRefCounts [networkableId] = nil
		
		self:DispatchNetworkableDestroyed (networkableId)
		
		networkable:SetNetworkableHost (nil)
		
		-- Unhook networkable
		self:UnhookNetworkable (networkable)
	end
end

-- Internal, do not call
function self:GenerateNetworkableId ()
	local networkableId = math.random (1, 0xFFFFFFFF)
	
	while networkableId == 0 or
	      self:GetNetworkableById (networkableId) do
		networkableId = (networkableId + 1) % 4294967296
	end
	
	return networkableId
end

function self:CheckWeakNetworkables ()
	if SysTime () - self.LastWeakNetworkableCheckTime < self.WeakNetworkableCheckInterval then return end
	self.LastWeakNetworkableCheckTime = SysTime ()
	
	for networkableId, _ in pairs (self.NetworkableRefCounts) do
		if not self.NetworkablesById [networkableId] and
		   not self.WeakNetworkablesById [networkableId] then
			self.NetworkableRefCounts [networkableId] = nil
			
			self:DispatchNetworkableDestroyed (networkableId)
		end
	end
end

function self:DispatchNetworkableDestroyed (networkableId)
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:UInt8 (GLib.Networking.NetworkableHostMessageTypes.NetworkableDestroyed)
	outBuffer:UInt32 (networkableId)
	
	self:DispatchPacket (nil, outBuffer)
end

function self:HookNetworkable (networkable)
	if not networkable then return end
	
	networkable:AddEventListener ("DispatchPacket", "NetworkableHost." .. self:GetHashCode (),
		function (_, destinationId, packet)
			self:DispatchPacket (destinationId, packet, networkable)
		end
	)
end

function self:UnhookNetworkable (networkable)
	if not networkable then return end
	
	networkable:RemoveEventListener ("DispatchPacket", "NetworkableHost." .. self:GetHashCode ())
end