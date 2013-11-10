GLib.PolledWait (1, 30,
	function ()
		return ULib ~= nil
	end,
	function ()
		GLib.Lua.Detour ("ULib.getUsers",
			function (originalFunction, ...)
				local string_find = string.find
				string.find = function (str, substring)
					local matches, offset = GLib.UTF8.MatchTransliteration (str, substring)
					if matches then
						return offset
					end
					return nil
				end
				local r0, r1, r2 = originalFunction (...)
				string.find = string_find
				return r0, r1, r2
			end
		)

		GLib.Lua.Detour ("ULib.getUser",
			function (originalFunction, ...)
				local string_find = string.find
				string.find = function (str, substring)
					local matches, offset = GLib.UTF8.MatchTransliteration (str, substring)
					if matches then
						return offset
					end
					return nil
				end
				local r0, r1, r2 = originalFunction (...)
				string.find = string_find
				return r0, r1, r2
			end
		)
	end
)