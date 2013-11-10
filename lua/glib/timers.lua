local delayedCalls = {}

function GLib.CallDelayed (callback)
	if not callback then return end
	if type (callback) ~= "function" then
		GLib.Error ("GLib.CallDelayed : callback must be a function!")
		return
	end
	
	delayedCalls [#delayedCalls + 1] = callback
end

function GLib.PolledWait (interval, timeout, predicate, callback)
	if not callback then return end
	if not predicate then return end
	
	if predicate () then
		callback ()
		return
	end
	
	if timeout < 0 then return end
	
	timer.Simple (interval,
		function ()
			GLib.PolledWait (interval, timeout - interval, predicate, callback)
		end
	)
end

hook.Add ("Think", "GLib.DelayedCalls",
	function ()
		local startTime = SysTime ()
		while SysTime () - startTime < 0.005 and #delayedCalls > 0 do
			xpcall (delayedCalls [1], GLib.Error)
			table.remove (delayedCalls, 1)
		end
	end
)