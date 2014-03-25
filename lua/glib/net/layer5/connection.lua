local self = {}
GLib.Net.Layer5.Connection = GLib.MakeConstructor (self)

--[[
	Events:
		ActivityStateChanged (hasUndispatchedPackets)
			Fired when the connection's undispatched packet count decreases to 0 or increases to 1.
		Closed (ConnectionClosureReason closureReason)
			Fired when the connection has been closed.
		Opened (remoteId, InBuffer inBuffer)
			Fired when the first packet has been received.
		TimeoutChanged (timeout)
			Fired when the timeout period has changed.
]]

function self:ctor (channel, id, remoteId)
	-- Identity
	self.Channel  = channel
	self.Id       = id
	self.RemoteId = remoteId
	
	-- Handlers
	self.OpenHandler   = self.Channel:GetOpenHandler   () or GLib.NullCallback
	self.PacketHandler = self.Channel:GetPacketHandler () or GLib.NullCallback
	
	-- State
	self.State         = GLib.Net.Layer5.ConnectionState.Opening
	self.Initiator     = nil
	self.ClosureReason = nil
	
	-- Packets
	self.OpenPacketSent = false
	
	self.NextInboundPacketId  = 0
	self.NextOutboundPacketId = 0
	
	self.InboundPackets = {}
	self.OutboundQueue  = {}
	
	-- Timeouts
	self.Timeout     = 10
	self.TimeoutTime = math.huge
	
	GLib.EventProvider (self)
end

-- Identity
function self:GetChannel ()
	return self.Channel
end

function self:GetId ()
	return self.Id
end

function self:GetRemoteId ()
	return self.RemoteId
end

-- Handlers
function self:GetOpenHandler ()
	return self.OpenHandler
end

function self:GetPacketHandler ()
	return self.PacketHandler
end

function self:SetOpenHandler (openHandler)
	self.OpenHandler = openHandler
	return self
end

function self:SetPacketHandler (packetHandler)
	self.PacketHandler = packetHandler
	return self
end

-- State
function self:Close (reason)
	if self:IsClosed () then return end
	
	reason = reason or GLib.Net.Layer5.ConnectionClosureReason.LocalClosure
	
	local hasUndispatchedPackets = self:HasUndispatchedPackets ()
	if reason == GLib.Net.Layer5.ConnectionClosureReason.LocalClosure then
		self.State = GLib.Net.Layer5.ConnectionState.Closing
	else
		-- Close the connection immediately
		self:ClearOutboundQueue ()
		
		hasUndispatchedPackets = self:HasUndispatchedPackets ()
		
		self.State = GLib.Net.Layer5.ConnectionState.Closed
	end
	
	self.ClosureReason = reason
	
	if self:HasUndispatchedPackets () ~= hasUndispatchedPackets then
		self:DispatchEvent ("ActivityStateChanged", self:HasUndispatchedPackets ())
	end
	
	if self:IsClosed () then
		self:DispatchEvent ("Closed", self.ClosureReason)
	end
end

function self:GetInitiator ()
	return self.Initiator
end

function self:IsLocallyInitiated ()
	return self.Initiator == GLib.Net.Layer5.ConnectionEndPoint.Local
end

function self:IsRemotelyInitiated ()
	return self.Initiator == GLib.Net.Layer5.ConnectionEndPoint.Remote
end

function self:IsClosed ()
	return self.State == GLib.Net.Layer5.ConnectionState.Closed
end

function self:IsClosing ()
	return self.State == GLib.Net.Layer5.ConnectionState.Closing
end

function self:IsOpen ()
	return self.State == GLib.Net.Layer5.ConnectionState.Open
end

function self:IsOpening ()
	if self.State == GLib.Net.Layer5.ConnectionState.Opening then return true end
	if self:IsLocallyInitiated () and not self.OpenPacketSent then return true end
	
	return false
end

function self:SetInitiator (initiator)
	self.Initiator = initiator
	return self
end

-- Packets
function self:ClearOutboundQueue ()
	local hasUndispatchedPackets = self:HasUndispatchedPackets ()
	
	self.OutboundQueue = {}
	
	if self:HasUndispatchedPackets () ~= hasUndispatchedPackets then
		self:DispatchEvent ("ActivityStateChanged", self:HasUndispatchedPackets ())
	end
end

function self:DispatchPacket (packet)
	self:Write (packet)
end

function self:HasUndispatchedPackets ()
	return #self.OutboundQueue > 0 or self:IsClosing ()
end

function self:Write (packet)
	if self:IsClosing () then return end
	if self:IsClosed  () then return end
	
	local hasUndispatchedPackets = self:HasUndispatchedPackets ()
	
	self.OutboundQueue [#self.OutboundQueue + 1] = packet
	
	if self:HasUndispatchedPackets () ~= hasUndispatchedPackets then
		self:DispatchEvent ("ActivityStateChanged", self:HasUndispatchedPackets ())
	end
	
	-- Update timeout
	self:UpdateTimeout ()
end

-- Timeouts
function self:GetTimeout ()
	return self.Timeout
end

function self:GetTimeoutTime ()
	return self.TimeoutTime
end

function self:HasTimedOut (t)
	t = t or SysTime ()
	
	return t > self.TimeoutTime
end

function self:SetTimeout (timeout)
	self.Timeout = timeout
	
	self:DispatchEvent ("TimeoutChanged", self.Timeout)
end

function self:SetTimeoutTime (timeoutTime)
	self.TimeoutTime = timeoutTime
	
	self:DispatchEvent ("TimeoutChanged", self.Timeout)
end

function self:UpdateTimeout ()
	self:SetTimeoutTime (SysTime () + self.Timeout)
end

-- Internal, do not call
function self:GenerateNextPacket (outBuffer)
	if not self:HasUndispatchedPackets () then
		-- WTF, caller. You had one job.
		GLib.Error ("Connection:GenerateNextPacket : YOU HAD ONE JOB.")
		return
	end
	
	outBuffer = outBuffer or GLib.Net.OutBuffer ()
	outBuffer:UInt32 (self:GetId ())
	outBuffer:UInt32 (self.NextOutboundPacketId)
	self.NextOutboundPacketId = (self.NextOutboundPacketId + 1) % 4294967296
	
	local packetType = 0
	if #self.OutboundQueue > 0 then
		packetType = packetType + GLib.Net.Layer5.ConnectionPacketType.Data
	end
	if self:IsOpening () then
		packetType = packetType + GLib.Net.Layer5.ConnectionPacketType.Open
		self.OpenPacketSent = true
	end
	if self:IsClosing () and #self.OutboundQueue <= 1 then
		packetType = packetType + GLib.Net.Layer5.ConnectionPacketType.Close
	end
	
	outBuffer:UInt8 (packetType)
	
	if #self.OutboundQueue > 0 then
		outBuffer:OutBuffer (self.OutboundQueue [1])
		table.remove (self.OutboundQueue, 1)
	end
	
	if self:IsOpening () then
		-- Open the connection
		self.State = GLib.Net.Layer5.ConnectionState.Open
		self:DispatchEvent ("Opened")
	end
	if self:IsClosing () and #self.OutboundQueue == 0 then
		-- Close the connection
		self.State = GLib.Net.Layer5.ConnectionState.Closed
		self:DispatchEvent ("Closed", GLib.Net.Layer5.ConnectionClosureReason.LocalClosure)
	end
	
	if not self:HasUndispatchedPackets () then
		self:DispatchEvent ("ActivityStateChanged", self:HasUndispatchedPackets ())
	end
	
	-- Update timeout
	self:UpdateTimeout ()
	
	return outBuffer
end

function self:ProcessInboundPacket (inBuffer)
	if self:IsClosing () then return end
	if self:IsClosed  () then return end
	
	local packetId = inBuffer:UInt32 ()
	
	self.InboundPackets [packetId] = packetId == self.NextInboundPacketId and inBuffer or inBuffer:Pin ()
	
	-- Process sequential packets
	while self.InboundPackets [self.NextInboundPacketId] do
		self:ProcessPacket (self.NextInboundPacketId, self.InboundPackets [self.NextInboundPacketId])
		self.InboundPackets [self.NextInboundPacketId] = nil
		
		self.NextInboundPacketId = (self.NextInboundPacketId + 1) % 4294967296
	end
	
	-- Close if we've desynced
	if packetId - self.NextInboundPacketId > 32 then
		self:Close ()
	end
	
	-- Update timeout
	self:UpdateTimeout ()
end

function self:ProcessPacket (packetId, inBuffer)
	local packetType = inBuffer:UInt8 ()
	
	if bit.band (packetType, GLib.Net.Layer5.ConnectionPacketType.Open) ~= 0 then
		if self:IsOpening () then
			-- Open the connection
			self.State = GLib.Net.Layer5.ConnectionState.Open
			self:DispatchEvent ("Opened")
			
			self:GetOpenHandler () (self:GetRemoteId (), inBuffer, self)
		else
			-- Nope.avi
			self:Close ()
			return
		end
	end
	
	if bit.band (packetType, GLib.Net.Layer5.ConnectionPacketType.Data) ~= 0 then
		if self:IsOpening () then
			-- We didn't get a packet with the Open flag.
			self:Close ()
			return
		end
		self:GetPacketHandler () (self:GetRemoteId (), inBuffer, self)
	end
	
	if bit.band (packetType, GLib.Net.Layer5.ConnectionPacketType.Close) ~= 0 then
		self:Close (GLib.Net.Layer5.ConnectionClosureReason.RemoteClosure)
	end
	
	-- Update timeout
	self:UpdateTimeout ()
end