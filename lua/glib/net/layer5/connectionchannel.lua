local self = {}
GLib.Net.Layer5.ConnectionChannel = GLib.MakeConstructor (self, GLib.Net.Layer5.Channel)

--[[
	Events:
		ConnectionActivityStateChanged (Connection connection, hasUndispatchedPackets)
			Fired when a connection's undispatched packet count decreases to 0 or increases to 1.
		ConnectionCreated (Connection connection)
			Fired when a connection has been created.
		ConnectionOpened (Connection connection)
			Fired when a connection has been opened.
		ConnectionClosed (Connection connection)
			Fired when a connection has been closed.
		ConnectionTimeoutChanged (Connection connection, timeout)
			Fired when a connection's timeout period has changed.
]]

function self:ctor (channelName, handler, channel)
	self.Channel = channel
	
	self.OpenHandler   = handler or GLib.NullCallback
	self.PacketHandler = GLib.NullCallback
	
	self.Connections = {}
	
	self.Channel:SetHandler (
		function (sourceId, inBuffer)
			local connectionId = inBuffer:UInt32 ()
			
			self.Connections [sourceId] = self.Connections [sourceId] or {}
			local connection = self.Connections [sourceId] [connectionId]
			
			if not connection then
				-- New connection
				connection = GLib.Net.Layer5.Connection (self, connectionId, sourceId)
				connection:SetInitiator (GLib.Net.Layer5.ConnectionEndPoint.Remote)
				
				-- Register connection
				self:RegisterConnection (connection)
			end
			
			connection:ProcessInboundPacket (inBuffer)
		end
	)
	
	GLib.Net.Layer5.RegisterChannel (self)
end

function self:dtor ()
	for connection, _ in pairs (self.Connections) do
		connection:Close ()
	end
	
	GLib.Net.Layer5.UnregisterChannel (self)
end

function self:Connect (destinationId, packet)
	-- New connection
	local connection = GLib.Net.Layer5.Connection (self, self:GenerateConnectionId (destinationId), destinationId)
	connection:SetInitiator (GLib.Net.Layer5.ConnectionEndPoint.Local)
	
	-- Register connection
	self:RegisterConnection (connection)
	
	-- Write packet
	if packet then
		connection:Write (packet)
	end
	
	return connection
end

function self:DispatchPacket (destinationId, packet)
	return self:Connect (destinationId, packet)
end

function self:GetHandler ()
	return self:GetOpenHandler ()
end

function self:GetMTU ()
	return self.Channel:GetMTU () - 13
end

function self:GetOpenHandler ()
	return self.OpenHandler
end

function self:GetPacketHandler ()
	return self.PacketHandler
end

function self:IsOpen ()
	return self.Channel:IsOpen ()
end

function self:SetOpen (open)
	self.Channel:SetOpen (open)
end

function self:SetHandler (handler)
	return self:SetOpenHandler (handler)
end

function self:SetOpenHandler (openHandler)
	self.OpenHandler = openHandler
	return self
end

function self:SetPacketHandler (packetHandler)
	self.PacketHandler = packetHandler
	return self
end

-- Internal, do not call
function self:GenerateConnectionId (destinationId)
	local connectionId = math.random (0, 0xFFFFFFFF)
	
	if not self.Connections [destinationId] then return connectionId end
	
	while self.Connections [destinationId] [connectionId] do
		connectionId = (connectionId + 1) % 4294967296
	end
	
	return connectionId
end

function self:RegisterConnection (connection)
	-- Add connection to list
	self.Connections [connection:GetRemoteId ()] = self.Connections [connection:GetRemoteId ()] or {}
	self.Connections [connection:GetRemoteId ()] [connection:GetId ()] = connection
	
	-- Hook events
	self:HookConnection (connection)
	
	-- Dispatch event
	self:DispatchEvent ("ConnectionCreated", connection)
end

function self:ProcessConnectionOutboundQueue (connection)
	if connection:GetChannel () ~= self then return end
	if not connection:HasUndispatchedPackets () then return end
	
	self.Channel:DispatchPacket (connection:GetRemoteId (), connection:GenerateNextPacket ())
end

function self:HookConnection (connection)
	if not connection then return end
	
	connection:AddEventListener ("ActivityStateChanged", self:GetHashCode (),
		function (_, hasUndispatchedPackets)
			self:DispatchEvent ("ConnectionActivityStateChanged", connection, hasUndispatchedPackets)
		end
	)
	connection:AddEventListener ("Closed", self:GetHashCode (),
		function (_, closureReason)
			self:DispatchEvent ("ConnectionClosed", connection, closureReason)
			
			-- Unregister connection
			self:UnhookConnection (connection)
			self.Connections [connection:GetRemoteId ()] [connection:GetId ()] = nil
			if not next (self.Connections [connection:GetRemoteId ()]) then
				self.Connections [connection:GetRemoteId ()] = nil
			end
		end
	)
	connection:AddEventListener ("Opened", self:GetHashCode (),
		function (_)
			self:DispatchEvent ("ConnectionOpened", connection)
		end
	)
	connection:AddEventListener ("TimeoutChanged", self:GetHashCode (),
		function (_, timeout)
			self:DispatchEvent ("ConnectionTimeoutChanged", connection, timeout)
		end
	)
end

function self:UnhookConnection (connection)
	if not connection then return end
	
	connection:RemoveEventListener ("ActivityStateChanged", self:GetHashCode ())
	connection:RemoveEventListener ("Closed",               self:GetHashCode ())
	connection:RemoveEventListener ("Opened",               self:GetHashCode ())
	connection:RemoveEventListener ("TimeoutChanged",       self:GetHashCode ())
end