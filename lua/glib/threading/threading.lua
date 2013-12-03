GLib.Threading.Threads = {}
GLib.Threading.CurrentThread = nil

function GLib.CallAsync (f, ...)
	return GLib.Threading.Thread ():Start (f, ...)
end

function GLib.Curry (f, ...)
	local arguments = {...}
	if #arguments == 0 then return f end
	return function ()
		f (unpack (arguments))
	end
end

function GLib.Threading.CanYield ()
	if not GLib.Threading.CurrentThread then
		return coroutine.running () ~= nil
	end
	
	return GLib.Threading.CurrentThread:CanYield ()
end

function GLib.Threading.CanYieldTimeSlice ()
	if not GLib.Threading.CurrentThread then
		return coroutine.running () ~= nil
	end
	
	return GLib.Threading.CurrentThread:CanYieldTimeSlice ()
end

function GLib.Threading.CheckYield ()
	if not GLib.Threading.CurrentThread then return false end
	
	return GLib.Threading.CurrentThread:CheckYield ()
end

function GLib.Threading.GetCurrentThread ()
	return GLib.Threading.CurrentThread
end

GLib.CheckYield = GLib.Threading.CheckYield
GLib.GetCurrentThread = GLib.Threading.GetCurrentThread

hook.Add ("Think", "GLib.Threading",
	function ()
		if not GLib.Threading then
			hook.Remove ("Think", "GLib.Threading")
			return
		end
		
		GLib.Threading.LastThreadResumeTime = SysTime ()
		
		for thread, _ in pairs (GLib.Threading.Threads) do
			if SysTime () - GLib.Threading.LastThreadResumeTime > 0.005 then
				break
			end
			
			if not thread:IsSuspended () and not thread:IsWaiting () then
				local success, error = coroutine.resume (thread:GetCoroutine ())
				if not success then
					thread:Terminate ()
					ErrorNoHalt (error)
				end
			end
		end
	end
)