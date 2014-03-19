local channels = GLib_Net_Layer2_GetChannels and GLib_Net_Layer2_GetChannels () or {}
GLib.Net.Layer2.Channels = channels

function GLib_Net_Layer2_GetChannels ()
	return channels
end

GLib.EventProvider (GLib.Net.Layer2)

function GLib.Net.Layer2.DispatchPacket (destinationId, channelName, packet)
	if not GLib.Net.Layer2.Channels [channelName] then
		GLib.Error ("GLib.Net.Layer2.DispatchPacket : Channel " .. channelName .. " doesn't exist.")
		return
	end
	
	local channel = GLib.Net.Layer2.Channels [channelName]
	channel:DispatchPacket (destinationId, packet)
end

function GLib.Net.Layer2.RegisterChannel (channelName, handler)
	if type (channelName) == "string" then
		local channel = GLib.Net.Layer2.Channel (channelName, handler)
		GLib.Net.Layer2.RegisterChannel (channel)
		return
	end
	
	local channel = channelName
	local channelName = channel:GetName ()
	
	if GLib.Net.Layer2.Channels [channelName] then
		channel:SetOpen (GLib.Net.Layer2.Channels [channelName]:IsOpen ())
	end
	
	GLib.Net.Layer2.Channels [channelName] = channel
	
	if SERVER then
		channel:SetOpen (true)
	end
	
	GLib.Net.Layer2:DispatchEvent ("ChannelRegistered", channel)
end

function GLib.Net.Layer2.UnregisterChannel (channelName)
	if type (channelName) ~= "string" then
		GLib.Net.Layer2.UnregisterChannel (channelName:GetName ())
		return
	end
	
	if not GLib.Net.Layer2.Channels [channelName] then return end
	
	local channel = GLib.Net.Layer2.Channels [channelName]
	GLib.Net.Layer2.Channels [channelName] = nil
	
	GLib.Net.Layer2:DispatchEvent ("ChannelUnregistered", channel)
end

function GLib.Net.Layer2.IsChannelOpen (channelName)
	if not GLib.Net.Layer2.Channels [channelName] then return false end
	
	return GLib.Net.Layer2.Channels [channelName]:IsOpen ()
end