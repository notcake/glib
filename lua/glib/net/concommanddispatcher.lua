local self = {}
GLib.Net.ConCommandDispatcher = GLib.MakeConstructor (self, GLib.StringOutBuffer)

function self:ctor ()
	self.Queue = {}
	
	hook.Add ("Tick", "GLib.ConCommandDispatcher",
		function ()
			if #self.Queue == 0 then return end
			
			for i = 1, 10 do
				RunConsoleCommand ("glib_data", self.Queue [1])
				table.remove (self.Queue, 1)
				
				if #self.Queue == 0 then break end
			end
			if #self.Queue == 0 then
				RunConsoleCommand ("glib_data", "\3")
			end
		end
	)
end

function self:dtor ()
	hook.Remove ("Tick", "GLib.ConCommandDispatcher")
end

function self:Dispatch (ply, channelName, packet)
	self.Data = ""
	self:String (channelName)
	for i = 1, #packet.Data do
		local data = packet.Data [i]
		local typeId = packet.Types [i]
		
		self [GLib.Net.DataType [typeId]] (self, data)
	end
	self.Data = self.Data:gsub ("\\", "\\\\")
	self.Data = self.Data:gsub ("%z", "\\0")
	self.Data = self.Data:gsub ("\t", "\\t")
	self.Data = self.Data:gsub ("\r", "\\r")
	self.Data = self.Data:gsub ("\n", "\\n")
	self.Data = self.Data:gsub ("\"", "\\q")

	local chunkSize = 497
	for i = 1, self.Data:len (), chunkSize do
		self.Queue [#self.Queue + 1] = (i == 1 and "\2" or "\1") .. self.Data:sub (i, i + chunkSize - 1)
	end
	if #self.Queue > 100 then
		ErrorNoHalt ("GLib.Net : Warning: Concommand queue is now " .. #self.Queue .. " items long.\n")
	end
end

function self:Boolean (b)
	self:UInt8 (b and 2 or 1)
end

GLib.Net.ConCommandDispatcher = GLib.Net.ConCommandDispatcher ()