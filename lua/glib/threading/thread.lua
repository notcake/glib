local self = {}
GLib.Threading.Thread = GLib.MakeConstructor (self, GLib.Threading.IWaitable)

--[[
	StateChanged (ThreadState state, bool suspended)
		Fired when this Thread's state has changed.
	Terminated ()
		Fired when this Thread has terminated
]]

function self:ctor ()
	-- Identity
	self.Name = nil
	
	-- Thread
	self.ThreadRunner = nil
	self.Coroutine = nil
	
	self.YieldTimeSliceAllowed = true
	
	-- State
	self.State = GLib.Threading.ThreadState.Unstarted
	self.Suspended = false -- Suspension can occur on top of running, waiting and sleeping
	
	self.StartTime = 0
	self.EndTime   = 0
	
	GLib.EventProvider (self)
end

-- Identity
function self:GetId ()
	return self:GetHashCode ()
end

function self:GetName ()
	return self.Name or self:GetId ()
end

function self:SetName (name)
	self.Name = name
	return self
end

function self:GetCoroutine ()
	return self.Coroutine
end

function self:GetEndTime ()
	return self.EndTime
end

function self:GetStartTime ()
	return self.StartTime
end

-- Thread
function self:GetThreadRunner ()
	return self.ThreadRunner
end

function self:IsMainThread ()
	return false
end

function self:SetThreadRunner (threadRunner)
	if self.ThreadRunner == threadRunner then return self end
	
	if self.ThreadRunner then
		self.ThreadRunner:RemoveThread (self)
	end
	
	self.ThreadRunner = threadRunner
	
	if self.ThreadRunner then
		self.ThreadRunner:AddThread (self)
	end
	
	return self
end

-- Thread control
function self:GetExecutionTime ()
	if not self:IsStarted () then return 0 end
	
	if self:IsTerminated () then
		return self.EndTime - self.StartTime
	end
	
	return SysTime () - self.StartTime
end

function self:GetState ()
	return self.State
end

function self:IsRunnable ()
	return not self.Suspended and self.State == GLib.Threading.ThreadState.Running
end

function self:IsRunning ()
	return GLib.Threading.CurrentThread == self
end

function self:IsStarted ()
	return self.State ~= GLib.Threading.ThreadState.Unstarted
end

function self:IsSuspended ()
	return self.Suspended
end

function self:IsTerminated ()
	return self.State == GLib.Threading.ThreadState.Terminated
end

function self:IsWaiting ()
	return self.State == GLib.Threading.ThreadState.Waiting
end

function self:Resume ()
	if not self:IsSuspended () then return self end
	
	self.Suspended = false
	
	self:DispatchEvent ("StateChanged", self.State, self.Suspended)
	
	return self
end

function self:Start (f, ...)
	if self.State ~= GLib.Threading.ThreadState.Unstarted then return self end
	
	self.ThreadRunner = self.ThreadRunner or GLib.Threading.ThreadRunner
	self.ThreadRunner:AddThread (self)
	
	self:SetState (GLib.Threading.ThreadState.Running)
	
	f = GLib.Curry (f, ...)
	
	self.Coroutine = coroutine.create (
		function ()
			self.StartTime = SysTime ()
			f ()
			self:Terminate (true)
		end
	)
	
	return self
end

function self:Suspend ()
	if self:IsSuspended () then return self end
	
	self.Suspended = true
	
	self:DispatchEvent ("StateChanged", self.State, self.Suspended)
	
	return self
end

function self:Terminate (doNotYield)
	if self.State == GLib.Threading.ThreadState.Terminated then return self end
	
	self.EndTime = SysTime ()
	self:SetState (GLib.Threading.ThreadState.Terminated)
	
	if not doNotYield then
		self:Yield ()
	end
	
	return self
end

-- Waits
function self:WaitForMultipleObjects (...)
	GLib.Error ("Thread:WaitForMultipleObjects : Not implemented.")
end

function self:WaitForSingleObject (waitable, timeout)
	if timeout ~= nil then
		GLib.Error ("Thread:WaitForSingleObject : Timeouts are not implemented yet.")
	end
	
	self:SetState (GLib.Threading.ThreadState.Waiting)
	waitable:Wait (
		function ()
			self:SetState (GLib.Threading.ThreadState.Running)
		end
	)
	
	if self:IsRunning () and not self:IsRunnable () then
		if GLib.Threading.CanYieldTimeSlice () then
			self:Yield ()
		else
			-- The IWaitable better be resolvable.
			if waitable:Is (GLib.Threading.Thread) then
				waitable:ResolveWait ()
			else
				GLib.Error ("Thread:WaitForSingleObject : Thread " .. self:GetName () .. " cannot yield.")
			end
		end
	end
end

-- IWaitable
function self:IsResolvableWaitable ()
	return true
end

function self:ResolveWait ()
	local canYieldTimeSlice = self:CanYieldTimeSlice ()
	self:SetYieldTimeSliceAllowed (false)
	self.ThreadRunner:RunThread (self)
	self:SetYieldTimeSliceAllowed (canYieldTimeSlice)
	
	if not self:IsTerminated () then
		GLib.Error ("Thread:WaitForSingleObject : Thread " .. self:GetName () .. " did not run until completion.")
	end
end

function self:WaitCallback (callback)
	if self:IsTerminated () then
		callback (GLib.Threading.WaitEndReason.Success)
	else
		self:AddEventListener ("Terminated",
			function ()
				callback (GLib.Threading.WaitEndReason.Success)
			end
		)
	end
end

-- Cooperative threading
function self:CanYield ()
	return true
end

function self:CanYieldTimeSlice ()
	return self.YieldTimeSliceAllowed
end

function self:CheckYield ()
	if not self:IsRunning () then return false end
	if not self:CanYieldTimeSlice () then return false end
	
	if SysTime () > self.ThreadRunner:GetExecutionSliceEndTime () then
		self:Yield ()
		return true
	end
	
	return false
end

function self:SetYieldTimeSliceAllowed (yieldTimeSliceAllowed)
	if yieldTimeSliceAllowed == nil then
		yieldTimeSliceAllowed = true
	end
	
	self.YieldTimeSliceAllowed = yieldTimeSliceAllowed
	return self
end

function self:Yield ()
	if not self:IsRunning () then return end
	if not self:CanYield () then
		GLib.Error ("Thread:Yield : Thread " .. self:GetName () .. " is not able to yield.")
		return
	end
	
	coroutine.yield ()
end

-- Internal, do not call
function self:SetState (state)
	self.State = state
	self:DispatchEvent ("StateChanged", self.State, self.Suspended)
end