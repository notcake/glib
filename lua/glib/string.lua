GLib.String = {}

function GLib.String.ConsoleEscape (str)
	if type (str) ~= "string" then
		ErrorNoHalt ("GLib.String.ConsoleEscape: Expected string, got " .. type (str) .. " instead.\n")
		return ""
	end
	return str
		:gsub ("\\", "\\\\")
		:gsub ("\r", "\\r")
		:gsub ("\n", "\\n")
		:gsub ("\t", "\\t")
		:gsub ("\"", "\\q")
		:gsub ("\'", "\\s")
end

function GLib.String.Escape (str)
	if type (str) ~= "string" then
		ErrorNoHalt ("GLib.String.Escape: Expected string, got " .. type (str) .. " instead.\n")
		return ""
	end
	return str
		:gsub ("\\", "\\\\")
		:gsub ("\r", "\\r")
		:gsub ("\n", "\\n")
		:gsub ("\t", "\\t")
		:gsub ("\"", "\\\"")
		:gsub ("\'", "\\\'")
end

function GLib.String.EscapeWhitespace (str)
	if type (str) ~= "string" then
		ErrorNoHalt ("GLib.String.EscapeNewlines: Expected string, got " .. type (str) .. " instead.\n")
		return ""
	end
	return str
		:gsub ("\r", "\\r")
		:gsub ("\n", "\\n")
		:gsub ("\t", "\\t")
end