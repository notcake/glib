local self = {}
GLib.Threading.IWaitable = GLib.MakeConstructor (self)

function self:ctor ()
end

function self:IsResolvableWaitable ()
	return false
end

function self:ResolveWait ()
	if self:IsResolvableWait () then
		GLib.Error ("IWaitable:ResolveWait : Not implemented.")
	else
		GLib.Error ("IWaitable:ResolveWait : This IWaitable is non-resolvable.")
	end
end

function self:Wait (callback)
	if callback then
		self:WaitCallback (callback)
	else
		GLib.Threading.CurrentThread:WaitForSingleObject (self)
	end
end

function self:WaitCallback (callback)
	GLib.Error ("IWaitable:WaitCallback : Not implemented.")
end