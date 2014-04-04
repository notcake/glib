local self = {}
GLib.Networking.ConnectionNetworkable = GLib.MakeConstructor (self, GLib.Networking.Networkable)

function self:ctor (connection)
	self.Connection = connection
	self:HookConnection (connection)
end

function self:dtor ()
	self:UnhookConnection (connection)
end

-- Identity
function self:GetRemoteId ()
	return self.Connection:GetRemoteId ()
end

function self:GetConnection ()
	return self.Connection
end

-- State
function self:Close (reason)
	return self.Connection:Close (reason)
end

-- Packets
function self:DispatchPacket (destinationId, packet)
	if destinationId and destinationId ~= self:GetRemoteId () then
		GLib.Error ("ConnectionNetworkable:DispatchPacket : Destination ID does not match remote ID!")
		return
	end
	self.Connection:DispatchPacket (packet)
end

function self:HandlePacket (sourceId, inBuffer)
	if sourceId ~= self:GetRemoteId () then return end
	return self.Connection:HandlePacket (inBuffer)
end

function self:Read (packet)
	return self.Connection:Read (packet)
end

function self:Write (packet)
	return self.Connection:Write (packet)
end

-- Handlers
function self:SetPacketHandler (packetHandler)
	self.Connection:SetPacketHandler (packetHandler)
	return self
end

-- Internal, do not call
function self:HookConnection (connection)
	if not connection then return end
	
	connection:AddEventListener ("Closed", "ConnectionNetworkable",
		function (_, connectionClosureReason)
			self:DispatchEvent ("Closed", connectionClosureReason)
			self:dtor ()
		end
	)
	connection:AddEventListener ("DispatchPacket", "ConnectionNetworkable",
		function (_, packet)
			self:DispatchEvent ("DispatchPacket", self:GetRemoteId (), packet)
		end
	)
end

function self:UnhookConnection (connection)
	if not connection then return end
	
	connection:RemoveEventListener ("Closed",         "ConnectionNetworkable")
	connection:RemoveEventListener ("DispatchPacket", "ConnectionNetworkable")
end