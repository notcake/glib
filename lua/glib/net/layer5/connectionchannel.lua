local self = {}
GLib.Net.Layer5.ConnectionChannel = GLib.MakeConstructor (self)

function self:ctor (channel, handler)
	self.Channel = channel
	self.Handler = handler
	
	self.Connections = {}
	
	self.Channel:SetHandler (
		function (sourceId, inBuffer)
			local connectionId = inBuffer:UInt32 ()
			
			self.Connections [sourceId] = self.Connections [sourceId] or {}
			local connection = self.Connections [sourceId] [connectionId]
			
			if not connection then
				connection = GLib.Net.Layer5.Connection (connectionId, sourceId)
				self.Connections [sourceId] [connectionId] = connection
			end
			
			connection:ProcessInboundPacket (inBuffer)
		end
	)
end

function self:Connect (destinationId, packet)
	local connection = GLib.Net.Layer5.Connection (self:GenerateConnectionId (destinationId), destinationId)
	self.Connections [destinationId] = self.Connections [destinationId] or destinationId
	connection:Write (packet)
	
	return connection
end

function self:GetHandler ()
	return self.Handler
end

function self:SetHandler (handler)
	self.Handler = handler
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