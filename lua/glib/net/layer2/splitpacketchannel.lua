local self = {}
GLib.Net.Layer2.SplitPacketChannel = GLib.MakeConstructor (self, GLib.Net.Layer2.Channel)

function self:ctor (channelName, handler, channel)
	self.Channel = channel
	
	self.NextPacketId = 1
	
	self.Active = false
	self.InboundPackets  = {}
	self.OutboundPackets = {}
	
	self.Channel:SetHandler (
		function (sourceId, inBuffer)
			local packetType = inBuffer:UInt8 ()
			local packetId   = inBuffer:UInt32 ()
			
			local inboundSplitPacket = nil
			if packetType == 1 then
				-- New split packet
				inboundSplitPacket = GLib.Net.Layer2.InboundSplitPacket (packetId)
				
				self.InboundPackets [sourceId] = self.InboundPackets [sourceId] or {}
				self.InboundPackets [sourceId] [packetId] = inboundSplitPacket
				
				inboundSplitPacket:DeserializeFirstChunk (inBuffer)
			elseif packetType == 2 then
				-- Continuation of split packet
				if not self.InboundPackets [sourceId] then return end
				
				inboundSplitPacket = self.InboundPackets [sourceId] [packetId]
				if not inboundSplitPacket then return end
				
				inboundSplitPacket:DeserializeNextChunk (inBuffer)
			end
			
			if inboundSplitPacket:IsFinished () then
				-- Clean up
				self.InboundPackets [sourceId] [packetId] = nil
				if not next (self.InboundPackets [sourceId]) then
					self.InboundPackets [sourceId] = nil
				end
				
				-- Enter idle state if appropriate
				if not next (self.InboundPackets) and
				   not next (self.OutboundPackets) then
					self.Active = false
					self:UnhookSystems ()
				end
				
				-- Invoke handler
				self:GetHandler () (sourceId, GLib.StringInBuffer (inboundSplitPacket:GetData ()))
			end
		end
	)
end

function self:dtor ()
	self:UnhookSystems ()
	
	self.Channel:dtor ()
end

function self:DispatchPacket (destinationId, packet)
	if not self.Active then
		self.Active = true
		self:HookSystems ()
	end
	
	self.OutboundPackets [destinationId] = self.OutboundPackets [destinationid] or {}
	
	local outboundSplitPacket = GLib.Net.Layer2.OutboundSplitPacket (self.NextPacketId, packet:GetString ())
	outboundSplitPacket:SetChunkSize (math.floor (self.Channel:GetMTU () / 2))
	self.NextPacketId = (self.NextPacketId + 1) % 4294967296
	
	self.OutboundPackets [destinationId] [outboundSplitPacket:GetId ()] = outboundSplitPacket
end

function self:GetChannel ()
	return self.Channel
end

-- Internal, do not call
function self:HookSystems ()
	timer.Create ("GLib.SplitPacketChannel." .. self:GetName (), 0.5, 0,
		function ()
			for userId, outboundSplitPackets in pairs (self.OutboundPackets) do
				for packetId, outboundSplitPacket in pairs (outboundSplitPackets) do
					local outBuffer = GLib.Net.OutBuffer ()
					if not outboundSplitPacket:IsStarted () then
						-- New split packet
						outBuffer:UInt8 (1)
						outBuffer:UInt32 (outboundSplitPacket:GetId ())
						outboundTransfer:SerializeFirstChunk (outBuffer)
					else
						-- Continuation of split packet
						outBuffer:UInt8 (2)
						outBuffer:UInt32 (outboundSplitPacket:GetId ())
						outboundTransfer:SerializeNextChunk (outBuffer)
					end
					
					self.Channel:DispatchPacket (userId, packet)
					
					-- Clean up if we're done
					if outboundSplitPacket:IsFinished () then
						outboundSplitPackets [packetId] = nil
					end
				end
				
				-- Clean up if we're done
				if not next (outboundSplitPackets) then
					self.OutboundPackets [userId] = nil
				end
			end
			
			-- Enter idle state if appropriate
			if not next (self.InboundPackets) and
			   not next (self.OutboundPackets) then
				self.Active = false
				self:UnhookSystems ()
			end
		end
	)
	
	GLib.PlayerMonitor:AddEventListener ("GLib.SplitPacketChannel." .. self:GetName (),
		function (_, ply, userId)
			self.InboundPackets  [userId] = nil
			self.OutboundPackets [userid] = nil
		end
	)
end

function self:UnhookSystems ()
	timer.Destroy ("GLib.SplitPacketChannel." .. self:GetName ())
	GLib.PlayerMonitor:RemoveEventListener ("PlayerDisconnected", "GLib.SplitPacketChannel." .. self:GetName ())
end