GLib.Net = {}
GLib.Net.PlayerMonitor = GLib.PlayerMonitor ("GLib.Net")
GLib.Net.ChannelHandlers = {}
GLib.Net.ChannelQueues = {} -- used on client only to queue up packets to be sent to the server
GLib.Net.OpenChannels = {}

local function PlayerFromId (userId)
	if userId == "Everyone" then return player.GetAll () end
	local ply = GLib.Net.PlayerMonitor:GetUserEntity (userId)
	if not ply then
		ErrorNoHalt ("GLib: PlayerFromId (" .. tostring (userId) .. ") failed to find player!\n")
	end
	return ply
end

-- Packet transmission
if SERVER then
	function GLib.Net.DispatchPacket (destinationId, channelName, packet)
		local ply = PlayerFromId (destinationId)
		if not ply then
			GLib.Error ("GLib.Net.DispatchPacket: Destination " .. destinationId .. " not found.")
			return
		end
		if packet:GetSize () + channelName:len () > 255 then
			GLib.Net.NetDispatcher:Dispatch (ply, channelName, packet)
		else
			GLib.Net.UsermessageDispatcher:Dispatch (ply, channelName, packet)
		end
	end
elseif CLIENT then
	function GLib.Net.DispatchPacket (destinationId, channelName, packet)
		if GLib.Net.IsChannelOpen (channelName) then
			GLib.Net.NetDispatcher:Dispatch (destinationId, channelName, packet)
		else
			GLib.Debug ("GLib.Net : Channel " .. channelName .. " is not open.\n")
			GLib.Net.ChannelQueues [channelName] = GLib.Net.ChannelQueues [channelName] or {}
			if #GLib.Net.ChannelQueues [channelName] > 256 then
				GLib.Error ("GLib.Net.DispatchPacket : " .. channelName .. " queue is growing too long!")
			end
			GLib.Net.ChannelQueues [channelName] [#GLib.Net.ChannelQueues [channelName] + 1] = packet
			packet.DestinationId = destinationId
		end
	end
end

function GLib.Net.IsChannelOpen (channelName)
	return GLib.Net.OpenChannels [channelName] and true or false
end

-- Packet reception
function GLib.Net.RegisterChannel (channelName, handler)
	GLib.Net.ChannelHandlers [channelName] = handler

	if SERVER then
		for _, ply in GLib.Net.PlayerMonitor:GetPlayerEnumerator () do
			umsg.Start ("glib_channel_open", ply)
				umsg.String (channelName)
			umsg.End ()
		end
		
		GLib.Net.OpenChannels [channelName] = true
		
		util.AddNetworkString (channelName)
		
		net.Receive (channelName,
			function (_, ply)
				handler (ply:SteamID (), GLib.Net.NetInBuffer ())
			end
		)
	elseif CLIENT then
		net.Receive (channelName,
			function (_)
				handler (GAuth.GetServerId (), GLib.Net.NetInBuffer ())
			end
		)
		
		usermessage.Hook (channelName,
			function (umsg)
				handler (GAuth.GetServerId (), GLib.Net.UsermessageInBuffer (umsg))
			end
		)
	end
end

if SERVER then
	GLib.Net.ConCommandBuffers = {}

	GLib.Net.PlayerMonitor:AddEventListener ("PlayerConnected",
		function (_, ply, userId)
			for channelName, _ in pairs (GLib.Net.OpenChannels) do
				umsg.Start ("glib_channel_open", ply)
					umsg.String (channelName)
				umsg.End ()
			end
		end
	)

	GLib.Net.PlayerMonitor:AddEventListener ("PlayerDisconnected",
		function (_, ply)
			GLib.Net.ConCommandBuffers [ply:SteamID ()] = nil
		end
	)
	
	concommand.Add ("glib_request_channels",
		function (ply, _, _)
			if not ply or not ply:IsValid () then return end
			for channelName, _ in pairs (GLib.Net.OpenChannels) do
				umsg.Start ("glib_channel_open", ply)
					umsg.String (channelName)
				umsg.End ()
			end
		end
	)
	
	concommand.Add ("glib_data",
		function (ply, _, args)
			local steamId = ply:SteamID ()
			if not args [1] then return end
			
			GLib.Net.ConCommandBuffers [steamId] = GLib.Net.ConCommandBuffers [steamId] or ""
			
			if args [1]:sub (1, 1) == "\2" or args [1]:sub (1, 1) == "\3" then
				if GLib.Net.ConCommandBuffers [steamId] ~= "" then
					local inBuffer = GLib.Net.ConCommandInBuffer (GLib.Net.ConCommandBuffers [steamId])
					local channelName = inBuffer:String ()
					local handler = GLib.Net.ChannelHandlers [channelName]
					if not handler then
						ErrorNoHalt ("glib_data : From " .. steamId .. ": No handler for " .. GLib.PrettifyString (channelName) .. "\n")
						ErrorNoHalt ("Original data: " .. GLib.PrettifyString (GLib.Net.ConCommandBuffers [steamId]):sub (1, 100) .. "\n")
					end
					if handler then
						local success, error = pcall (handler, steamId, inBuffer)
						if not success then ErrorNoHalt (error) end
					end
					GLib.Net.ConCommandBuffers [steamId] = ""
				end
			end
			GLib.Net.ConCommandBuffers [steamId] = GLib.Net.ConCommandBuffers [steamId] .. args [1]:sub (2)
		end
	)
elseif CLIENT then
	usermessage.Hook ("glib_channel_open", function (umsg)
		local channelName = umsg:ReadString ()
		GLib.Net.OpenChannels [channelName] = true
		
		if GLib.Net.ChannelQueues [channelName] then
			for _, packet in ipairs (GLib.Net.ChannelQueues [channelName]) do
				GLib.Net.DispatchPacket (packet.DestinationId, channelName, packet)
			end
			GLib.Net.ChannelQueues [channelName] = {}
		end
	end)
	
	local function RequestChannelList ()
		if not LocalPlayer or
			not LocalPlayer () or
			not LocalPlayer ():IsValid () then
			timer.Simple (0.001, RequestChannelList)
		end
		
		RunConsoleCommand ("glib_request_channels")
	end
	RequestChannelList ()
end