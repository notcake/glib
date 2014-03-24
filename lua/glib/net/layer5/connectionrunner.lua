local self = {}
GLib.Net.Layer5.ConnectionRunner = GLib.MakeConstructor (self)

function self:ctor ()
	self.Channels = GLib.WeakKeyTable ()
	
	self.ConnectionsByRemoteEndPoint = {}
	self.ActiveConnections  = GLib.WeakKeyTable () -- Connections with undispatched packets.
	self.TimeoutConnections = GLib.WeakKeyTable () -- Connections with timeouts.
	
	GLib.Net.Layer5:AddEventListener ("ChannelRegistered", self:GetHashCode (),
		function (_, channel)
			self:RegisterChannel (channel)
		end
	)
	
	GLib.Net.Layer5:AddEventListener ("ChannelUnregistered", self:GetHashCode (),
		function (_, channel)
			self:UnregisterChannel (channel)
		end
	)
	
	hook.Add ("Tick", "GLib.Net.Layer5.ConnectionRunner",
		function ()
			-- Outbound packets
			for connection, _ in pairs (self.ActiveConnections) do
				connection:GetChannel ():ProcessConnectionOutboundQueue (connection)
			end
			
			-- Check timeouts
			for connection, _ in pairs (self.TimeoutConnections) do
				if connection:HasTimedOut () then
					connection:Close (GLib.Net.Layer5.ConnectionClosureReason.Timeout)
				end
			end
		end
	)
end

function self:dtor ()
	GLib.Net.Layer5:RemoveEventListener ("ChannelRegistered",   self:GetHashCode ())
	GLib.Net.Layer5:RemoveEventListener ("ChannelUnregistered", self:GetHashCode ())
	
	hook.Remove ("Tick", "GLib.Net.Layer5.ConnectionRunner")
end

function self:RegisterChannel (channel)
	if self.Channels [channel] then return end
	
	self.Channels [channel] = true
	
	self:HookChannel (channel)
end

function self:UnregisterChannel (channel)
	if not self.Channels [channel] then return end
	
	self.Channels [channel] = nil
	
	self:UnhookChannel (channel)
end

-- Internal, do not call
function self:HookChannel (channel)
	if not channel then return end
	
	channel:AddEventListener ("ConnectionCreated", self:GetHashCode (),
		function (_, connection)
			self:HookConnection (connection)
			
			-- Register connection
			self.ConnectionsByRemoteEndPoint [connection:GetRemoteId ()] = self.ConnectionsByRemoteEndPoint [connection:GetRemoteId ()] or GLib.WeakKeyTable ()
			self.ConnectionsByRemoteEndPoint [connection:GetRemoteId ()] [connection] = true
			
			self:UpdateConnectionState (connection)
		end
	)
end

function self:UnhookChannel (channel)
	if not channel then return end
	
	channel:RemoveEventListener ("ConnectionCreated", self:GetHashCode ())
end

function self:HookConnection (connection)
	if not connection then return end
	
	connection:AddEventListener ("ActivityStateChanged", self:GetHashCode (),
		function (_, hasUndispatchedPackets)
			self:UpdateConnectionState (connection)
		end
	)
	
	connection:AddEventListener ("Closed", self:GetHashCode (),
		function (_, closureReason)
			self:UnhookConnection (connection)
			
			-- Unregister connection
			self.ConnectionsByRemoteEndPoint [connection:GetRemoteId ()] [connection] = nil
			if not next (self.ConnectionsByRemoteEndPoint [connection:GetRemoteId ()]) then
				self.ConnectionsByRemoteEndPoint [connection:GetRemoteId ()] = nil
			end
			
			self:UpdateConnectionState (connection)
		end
	)
	
	connection:AddEventListener ("TimeoutChanged", self:GetHashCode (),
		function (_, hasUndispatchedPackets)
			self:UpdateConnectionState (connection)
		end
	)
end

function self:UnhookConnection (connection)
	if not connection then return end
	
	connection:RemoveEventListener ("ActivityStateChanged", self:GetHashCode ())
	connection:RemoveEventListener ("Closed",               self:GetHashCode ())
	connection:RemoveEventListener ("TimeoutChanged",       self:GetHashCode ())
end

function self:UpdateConnectionState (connection)
	local active = connection:HasUndispatchedPackets () and not connection:IsClosed ()
	local canTimeout = connection:GetTimeoutTime () < math.huge and not connection:IsClosed ()
	
	if active then
		self.ActiveConnections [connection] = true
	else
		self.ActiveConnections [connection] = nil
	end
	if canTimeout then
		self.TimeoutConnections [connection] = true
	else
		self.TimeoutConnections [connection] = nil
	end
end

GLib.Net.Layer5.ConnectionRunner = GLib.Net.Layer5.ConnectionRunner ()