local self = {}
GLib.Net.ConCommandInBuffer = GLib.MakeConstructor (self, GLib.StringInBuffer)

local unescapeTable =
{
	["\\"] = "\\",
	["0"]  = "\0",
	["t"]  = "\t",
	["r"]  = "\r",
	["n"]  = "\n",
	["q"]  = "\""
}

function self:ctor (data)
	self.Data = data:gsub ("\\(.)", unescapeTable)
end

function self:Boolean ()
	return self:UInt8 () == 2
end