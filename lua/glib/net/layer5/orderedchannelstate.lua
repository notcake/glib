GLib.Net.Layer5.OrderedChannelState = GLib.Enum (
	{
		Uninitialized, -- No packets received yet
		Initializing,  -- Initial 0.5 second buffering
		Initialized    -- Normal operation
	}
)