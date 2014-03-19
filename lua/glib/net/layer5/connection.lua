local self = {}
GLib.Net.Layer5.Connection = GLib.MakeConstructor (self)

function self:ctor ()
	self.Id = id
	
	GLib.EventProvider (self)
end

function self:GetId ()
	return self.Id
end