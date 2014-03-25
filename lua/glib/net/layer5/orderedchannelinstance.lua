local self = {}
GLib.Net.Layer5.OrderedChannelInstance = GLib.MakeConstructor (self)

function self:ctor (channel, remoteId)
	self.Channel  = channel
	self.RemoteId = remoteId
	
	self.NextInboundPacketId  = nil
	self.NextOutboundPacketId = 0
	
	self.InboundPackets = {}
end

function self:dtor ()
	timer.Destroy (self:GetTimeoutTimerName ())
end

function self:DispatchPacket (packet)
	packet:PrependUInt32 (self.NextOutboundPacketId)
	self.NextOutboundPacketId = (self.NextOutboundPacketId + 1) % 4294967296
	
	return self.Channel:GetInnerChannel ():DispatchPacket (self:GetRemoteId (), packet)
end

function self:GetChannel ()
	return self.Channel
end

function self:GetRemoteId ()
	return self.RemoteId
end

function self:GetTimeoutTimerName ()
	return "OrderedChannel." .. self:GetChannel ():GetName () .. "." .. self:GetRemoteId ().. ".Timeout"
end

function self:HandlePacket (inBuffer)
	local packetId = inBuffer:UInt32 ()
	
	-- Initialize if we haven't already
	if not self.NextInboundPacketId then
		self.NextInboundPacketId = (packetId - 128) % 4294967296
	end
	
	if (self.NextInboundPacketId - packetId) % 4294967296 < 128 then
		-- Drop packet, we received it too late
		return
	end
	
	self.InboundPackets [packetId] = packetId == self.NextInboundPacketId and inBuffer or inBuffer:Pin ()
	
	if not self:ProcessAvailablePackets () then
		self:ResetTimeoutTimer ()
	end
end

-- Internal, do not call
function self:ProcessAvailablePackets ()
	if not self.InboundPackets [self.NextInboundPacketId] then return false end
	
	while self.InboundPackets [self.NextInboundPacketId] do
		self:ProcessPacket (self.NextInboundPacketId, self.InboundPackets [self.NextInboundPacketId])
		self.InboundPackets [self.NextInboundPacketId] = nil
		
		self.NextInboundPacketId = (self.NextInboundPacketId + 1) % 4294967296
	end
	
	if not next (self.InboundPackets) then
		timer.Destroy (self:GetTimeoutTimerName ())
	else
		self:ResetTimeoutTimer ()
	end
	
	return true
end

function self:ProcessPacket (packetId, inBuffer)
	self.Channel:GetHandler () (self:GetRemoteId (), inBuffer)
end

function self:ResetTimeoutTimer ()
	timer.Create (self:GetTimeoutTimerName (), 5, 1,
		function ()
			local lowestPacketId = math.huge
			local lowestPacketIdDifference = math.huge
			
			if not next (self.InboundPackets) then return end -- wtf
			
			for packetId, _ in pairs (self.InboundPackets) do
				local packetIdDifference = packetId - self.NextInboundPacketId % 4294967296
				if packetIdDifference < lowestPacketIdDifference then
					lowestPacketId = packetId
					lowestPacketIdDifference = packetIdDifference
				end
			end
			
			self.NextInboundPacketId = lowestPacketId
			self:ProcessAvailablePackets ()
		end
	)
end