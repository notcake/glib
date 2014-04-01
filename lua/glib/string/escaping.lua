function GLib.String.ConsoleEscape (str)
	if type (str) ~= "string" then
		ErrorNoHalt ("GLib.String.ConsoleEscape: Expected string, got " .. type (str) .. " instead.\n")
		return ""
	end
	str = str
		:gsub ("\\", "\\\\")
		:gsub ("\r", "\\r")
		:gsub ("\n", "\\n")
		:gsub ("\t", "\\t")
		:gsub ("\"", "\\q")
		:gsub ("\'", "\\s")
	return str
end

function GLib.String.Escape (str)
	if type (str) ~= "string" then
		ErrorNoHalt ("GLib.String.Escape: Expected string, got " .. type (str) .. " instead.\n")
		return ""
	end
	str = str
		:gsub ("\\", "\\\\")
		:gsub ("\r", "\\r")
		:gsub ("\n", "\\n")
		:gsub ("\t", "\\t")
		:gsub ("\"", "\\\"")
		:gsub ("\'", "\\\'")
	return str
end

function GLib.String.EscapeNonprintable (str)
	if type (str) ~= "string" then
		ErrorNoHalt ("GLib.String.EscapeNonprintable: Expected string, got " .. type (str) .. " instead.\n")
		return ""
	end
	str = str:gsub (".",
		function (c)
			if c == "\\" then return "\\\\" end
			c = string.byte (c)
			if c < string.byte (" ") then return string.format ("\\x%02x", c) end
			if c >= 127 then return string.format ("\\x%02x", c) end
			if c == string.byte ("\"") then return "\\\"" end
		end
	)
	return str
end

function GLib.String.EscapeWhitespace (str)
	if type (str) ~= "string" then
		ErrorNoHalt ("GLib.String.EscapeNewlines: Expected string, got " .. type (str) .. " instead.\n")
		return ""
	end
	str = str
		:gsub ("\r", "\\r")
		:gsub ("\n", "\\n")
		:gsub ("\t", "\\t")
	return str
end