local self = {}
local ctor = GLib.MakeConstructor (self, GLib.Vector)

function GLib.RowVector (w, ...)
	return ctor (w, 1, ...)
end