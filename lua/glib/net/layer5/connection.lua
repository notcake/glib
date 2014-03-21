local self = {}
GLib.Net.Layer5.Connection = GLib.MakeConstructor (self)

--[[
	Events:
		ActivityStateChanged (hasUndispatchedPackets)
			Fired when the connection's undispatched packet count decreases to 0 or increases to 1.
		Closed (ConnectionClosureReason closureReason)
			Fired when the connection has been closed.
]]

function self:ctor (id, remoteId)
	self.Id       = id
	self.RemoteId = remoteId
	
	self.OpenHandler = GLib.NullCallback
	self.Handler     = GLib.NullCallback
	
	self.State = GLib.Net.Layer5.ConnectionState.Open
	self.ClosureReason = nil
	
	self.NextInboundPacketId  = 0
	self.NextOutboundPacketId = 0
	
	self.InboundPackets = {}
	self.OutboundQueue  = {}
	
	GLib.EventProvider (self)
end

function self:ClearOutboundQueue ()
	local hasUndispatchedPackets = self:HasUndispatchedPackets ()
	
	self.OutboundQueue = {}
	
	if self:HasUndispatchedPackets () ~= hasUndispatchedPackets then
		self:DispatchEvent ("ActivityStateChanged", self:HasUndispatchedPackets ())
	end
end

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

function self:DispatchPacket (packet)
	self:Write (packet)
end

function self:GetHandler ()
	return self.Handler
end

function self:GetId ()
	return self.Id
end

function self:GetOpenHandler ()
	return self.OpenHandler
end

function self:GetRemoteId ()
	return self.RemoteId
end

function self:HasUndispatchedPackets ()
	return #self.OutboundQueue > 0 or self:IsClosing ()
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

function self:SetHandler (handler)
	self.Handler = handler
	return self
end

function self:SetOpenHandler (openHandler)
	self.OpenHandler = openHandler
	return self
end

function self:Write (packet)
	if self:IsClosing () then return end
	if self:IsClosed () then return end
	
	self.OutboundQueue [#self.OutboundQueue + 1] = packet
end

-- Internal, do not call
function self:GenerateNextPacket (outBuffer)
	if not self:HasUndispatchedPacket () then
		-- WTF, caller. You had one job.
		GLib.Error ("Connection:GenerateNextPacket : YOU HAD ONE JOB.")
		return
	end
	
	outBuffer:UInt32 (self:GetId ())
	outBuffer:UInt32 (self.NextOutboundPacketId)
	self.NextOutboundPacketId = self.NextOutboundPacketId + 1
	
	if #self.OutboundQueue > 0 then
		if self:IsClosing () and
		   #self.OutboundQueue == 1 then
			outBuffer:UInt8 (GLib.Net.Layer5.ConnectionPacketType.Data + GLib.Net.Layer5.ConnectionPacketType.Close)
			
			-- Close the connection
			self.State = GLib.Net.Layer5.ConnectionState.Closed
			self:DispatchEvent ("Closed", GLib.Net.Layer5.ConnectionClosureReason.LocalClosure)
		else
			outBuffer:UInt8 (GLib.Net.Layer5.ConnectionPacketType.Data)
		end
		outBuffer:LongString (self.OutboundQueue [1]:GetString ())
	elseif self:IsClosing ()
		outBuffer:UInt8 (GLib.Net.Layer5.ConnectionPacketType.Close)
		
		-- Close the connection
		self.State = GLib.Net.Layer5.ConnectionState.Closed
		self:DispatchEvent ("Closed", GLib.Net.Layer5.ConnectionClosureReason.LocalClosure)
	end
	
	if not self:HasUndispatchedPacket () then
		self:DispatchEvent ("ActivityStateChanged", self:HasUndispatchedPackets ())
	end
end

function self:ProcessInboundPacket (inBuffer)
	if self:IsClosed () then return end
	
	local packetId = inBuffer:UInt32 ()
	
	self.InboundPackets [packetId] = inBuffer
	
	while self.InboundPackets [self.NextInboundPacketId] do
		self:ProcessPacket (self.InboundPackets [self.NextInboundPacketId])
		self.InboundPackets [self.NextInboundPacketId] = nil
	end
end

function self:ProcessPacket (inBuffer)
	local packetType = inBuffer:UInt8 ()
	
	if bit.band (packetType, GLib.Net.Layer5.ConnectionPacketType.Open) ~= 0 then
		self:GetOpenHandler () (self:GetRemoteId (), inBuffer, self)
	end
	
	if bit.band (packetType, GLib.Net.Layer5.ConnectionPacketType.Close) ~= 0 then
		self:Close (GLib.Net.Layer5.ConnectionClosureReason.RemoteClosure)
	end
	
	if bit.band (packetType, GLib.Net.Layer5.ConnectionPacketType.Data) ~= 0 then
		self:GetHandler () (self:GetRemoteId (), inBuffer, self)
	end
end