local self = {}
GLib.Net.Layer2.Channel = GLib.MakeConstructor (self, GLib.Net.Layer2.Channel)

function self:ctor (channelName, handler)
	self.UsermessageChannel = GLib.Net.Layer1.UsermessageChannel (channelName, handler)
	self.NetChannel         = GLib.Net.Layer1.NetChannel (channelName, handler)
	self.SplitPacketChannel = GLib.Net.Layer2.SplitPacketChannel (channelName, handler, GLib.Net.Layer1.NetChannel (channelName .. "#"))
	
	self.Queue = {}
	
	self.Open = false
	
	GLib.Net.Layer2.RegisterChannel (self)
end

function self:dtor ()
	self.UsermessageChannel:dtor ()
	self.NetChannel:dtor ()
	self.SplitPacketChannel:dtor ()
	
	GLib.Net.Layer2.UnregisterChannel (self)
end

function self:DispatchPacket (destinationId, packet)
	if not self:IsOpen () then
		-- Channel not open, queue up message
		self.Queue [#self.Queue + 1] = packet
		packet.DestinationId = destinationId
		
		if #self.Queue == 1024 then
			GLib.Error ("Channel:DispatchPacket : " .. self:GetName () .. " queue is growing too long!")
		end
		
		return
	end
	
	if packet:GetSize () <= self.UsermessageChannel:GetMTU () then
		self.UsermessageChannel:DispatchPacket (destinationId, packet)
	elseif packet:GetSize () <= self.NetChannel:GetMTU () then
		self.NetChannel:DispatchPacket (destinationId, packet)
	else
		self.SplitPacketChannel:DispatchPacket (destinationId, packet)
	end
end

function self:GetHandler ()
	return self.Handler
end

function self:IsOpen (destinationId)
	return self.Open
end

function self:SetOpen (open)
	self.Open = open
	
	self.UsermessageChannel:SetOpen (open)
	self.NetChannel:SetOpen (open)
	self.SplitPacketChannel:GetChannel ():SetOpen (open)
	self.SplitPacketChannel:SetOpen (open)
	
	-- Flush the queue if we've been opened
	if self.Open and #self.Queue > 0 then
		for _, packet in ipairs (self.Queue) do
			self:DispatchPacket (packet.DestinationId, packet)
		end
	end
	
	return self
end

function self:SetHandler (handler)
	self.Handler = handler
	
	self.UsermessageChannel:SetHandler (handler)
	self.NetChannel:SetHandler (handler)
	self.SplitPacketChannel:SetHandler (handler)
	
	return self
end