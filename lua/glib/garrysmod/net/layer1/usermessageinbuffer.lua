local self = {}
GLib.Net.Layer1.UsermessageInBuffer = GLib.MakeConstructor (self, GLib.Net.InBuffer)

function self:ctor (umsg)
	self.Usermessage = umsg
	
	self.Position = 1
end

function self:GetBytesRemaining ()
	return -1
end

function self:GetSize ()
	return -1
end

function self:IsEndOfStream ()
	return false
end

function self:UInt8 ()
	self.Position = self.Position + 1
	return self.Usermessage:ReadChar () + 128
end

function self:UInt16 ()
	self.Position = self.Position + 2
	return self.Usermessage:ReadShort () + 32768
end

function self:UInt32 ()
	self.Position = self.Position + 4
	return self.Usermessage:ReadLong () + 2147483648
end

function self:Int8 ()
	self.Position = self.Position + 1
	return self.Usermessage:ReadChar ()
end

function self:Int16 ()
	self.Position = self.Position + 2
	return self.Usermessage:ReadShort ()
end

function self:Int32 ()
	self.Position = self.Position + 4
	return self.Usermessage:ReadLong ()
end

function self:Float ()
	self.Position = self.Position + 4
	return self.Usermessage:ReadFloat ()
end

function self:Double ()
	self.Position = self.Position + 8
	return self.Usermessage:ReadFloat ()
end

function self:Vector ()
	self.Position = self.Position + 12
	return self.Usermessage:ReadVector ()
end

function self:Char ()
	self.Position = self.Position + 1
	return string.char (self:UInt8 ())
end

function self:Bytes (length)
	self.Position = self.Position + length
	
	local data = ""
	for i = 1, length do
		data = data .. self:Char ()
	end
	return data
end

function self:String ()
	local length = self:UInt8 ()
	return self:Bytes (length)
end

function self:Boolean ()
	self.Position = self.Position + 1
	return self.Usermessage:ReadChar () ~= 0
end