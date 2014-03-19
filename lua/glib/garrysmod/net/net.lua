function GLib.Net.DispatchPacket (destinationId, channelName, packet)
	return GLib.Net.Layer2.DispatchPacket (destinationId, channelName, packet)
end

function GLib.Net.RegisterChannel (channelName, handler)
	return GLib.Net.Layer2.RegisterChannel (channelName, handler)
end

function GLib.Net.UnregisterChannel (channelName)
	return GLib.Net.Layer2.UnregisterChannel (channelName)
end

function GLib.Net.IsChannelOpen (channelName)
	return GLib.Net.Layer2.IsChannelOpen (channelName)
end