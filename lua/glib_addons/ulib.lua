local function alternateStringFind (str, substring)
	local matches, offset = GLib.UTF8.MatchTransliteration (str, substring)
	if matches then
		return offset
	end
	return nil
end

GLib.PolledWait (1, 30,
	function ()
		return ULib ~= nil
	end,
	function ()
		GLib.Lua.Detour ({ "ULib.getUser", "ULib.getUsers" },
			function (originalFunction, ...)
				local string_find = string.find
				string.find = alternateStringFind
				
				GLib.Lua.Detour ("ULib.explode",
					function (originalFunction, ...)
						string.find = string_find
						
						local success, r0, r1, r2 = xpcall (originalFunction, GLib.Error, ...)
						
						string.find = alternateStringFind
						return r0, r1, r2
					end
				)
				
				local success, r0, r1, r2 = xpcall (originalFunction, GLib.Error, ...)
				
				GLib.Lua.Undetour ("ULib.explode")
				
				string.find = string_find
				return r0, r1, r2
			end
		)
	end
)