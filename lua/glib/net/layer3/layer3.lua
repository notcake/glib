local channels = GLib_Net_Layer3_GetChannels and GLib_Net_Layer3_GetChannels () or {}
GLib.Net.Layer3.Channels = channels

function GLib_Net_Layer3_GetChannels ()
	return channels
end

--[[
	Events:
		ChannelRegistered (Channel channel)
			Fired when a channel has been registered.
		ChannelUnregistered (Channel channel)
			Fired when a channel has been unregistered.
]]

GLib.EventProvider (GLib.Net.Layer3)

function GLib.Net.Layer3.DispatchPacket (destinationId, channelName, packet)
	local channel = GLib.Net.Layer3.GetChannel (channelName)
	if not channel then
		GLib.Error ("GLib.Net.Layer3.DispatchPacket : Channel " .. channelName .. " doesn't exist.")
		return
	end
	
	return channel:DispatchPacket (destinationId, packet)
end

function GLib.Net.Layer3.GetChannel (channelName)
	return GLib.Net.Layer3.Channels [channelName]
end

function GLib.Net.Layer3.RegisterChannel (channel, ...)
	if type (channel) == "string" then
		return GLib.Net.Layer3.RegisterChannelByName (channel, ...)
	end
	
	local channelName = channel:GetName ()
	
	if GLib.Net.Layer3.Channels [channelName] then
		channel:SetOpen (GLib.Net.Layer3.Channels [channelName]:IsOpen ())
	end
	
	GLib.Net.Layer3.Channels [channelName] = channel
	
	if SERVER then
		channel:SetOpen (true)
	end
	
	GLib.Net.Layer3:DispatchEvent ("ChannelRegistered", channel)
	
	return channel
end

function GLib.Net.Layer3.RegisterChannelByName (channelName, handler)
	local channel = GLib.Net.Layer3.GetChannel (channelName)
	if channel then
		channel:SetHandler (handler)
		return channel
	end
	
	channel = GLib.Net.Layer3.RoutedChannel (channelName, handler)
	return GLib.Net.Layer3.RegisterChannel (channel)
end

function GLib.Net.Layer3.UnregisterChannel (channelOrChannelName)
	if type (channelOrChannelName) ~= "string" then
		channelOrChannelName = channelOrChannelName:GetName ()
	end
	
	return GLib.Net.Layer3.UnregisterChannelByName (channelOrChannelName)
end

function GLib.Net.Layer3.UnregisterChannelByName (channelName)
	if not GLib.Net.Layer3.Channels [channelName] then return end
	
	local channel = GLib.Net.Layer3.Channels [channelName]
	GLib.Net.Layer3.Channels [channelName] = nil
	
	GLib.Net.Layer3:DispatchEvent ("ChannelUnregistered", channel)
end

function GLib.Net.Layer3.IsChannelOpen (channelName)
	if not GLib.Net.Layer3.Channels [channelName] then return false end
	
	return GLib.Net.Layer3.Channels [channelName]:IsOpen ()
end