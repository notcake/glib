local self = {}
GLib.Matrix = GLib.MakeConstructor (self)

function GLib.IdentityMatrix (size)
	local matrix = GLib.Matrix (size, size)
	for i = 0, size - 1 do
		matrix [1 + i * matrix.Width + i] = 1
	end
	
	return matrix
end

function self:ctor (w, h, m1, ...)
	self.Width  = w or 0
	self.Height = h or 0
	
	if m1 then
		local elements = { m1, ... }
		
		for i = 1, self.Width * self.Height do
			self [i] = elements [i] or 0
		end
	else
		for i = 1, self.Width * self.Height do
			self [i] = 0
		end
	end
end

function self:Clone (out)
	out = out or GLib.Matrix (self.Width, self.Height)
	
	out.Width  = self.Width
	out.Height = self.Height
	
	for i = 1, self:GetElementCount () do
		out [i] = self [i]
	end
	
	return out
end

function self:GetColumn (x, columnVector)
	columnVector = columnVector or GLib.ColumnVector (self.Height)
	columnVector.Width  = 1
	columnVector.Height = self.Height
	
	for y = 0, self.Height - 1 do
		columnVector [1 + y] = self [1 + y * self.Width + x - 1]
	end
	
	return columnVector
end

function self:GetElement (i)
	return self [i]
end

function self:GetElementCount ()
	return self.Width * self.Height
end

function self:GetWidth ()
	return self.Width
end

function self:GetHeight ()
	return self.Height
end

function self:GetRow (y, rowVector)
	rowVector = rowVector or GLib.RowVector (self.Width)
	rowVector.Width  = self.Width
	rowVector.Height = 1
	
	for x = 0, self.Width - 1 do
		rowVector [1 + x] = self [1 + (y - 1) * self.Width + x]
	end
	
	return rowVector
end

function self:Multiply (b, out)
	if out == self then out = nil end
	if out == b    then out = nil end
	
	if self.Width ~= b.Height then
		GLib.Error ("Matrix:Multiply : Left matrix has dimensions " .. self.Width .. "x" .. self.Height .. " and right matrix has incompatible dimensions " .. b.Width .. "x" .. b.Height .. ".")
		return nil
	end
	
	out = out or GLib.Matrix (b.Width, self.Height)
	out.Width  = b.Width
	out.Height = self.Height
	
	local element = 0
	for y = 0, self.Height - 1 do
		for x = 0, b.Width - 1 do
			element = 0
			for k = 0, self.Width - 1 do
				element = element + self [1 + y * self.Width + k] * b [1 + k * b.Width + x]
			end
			out [1 + y * out.Width + x] = element
		end
	end
	
	return out
end

function self:SetColumn (x, columnVector)
	for y = 0, self.Height - 1 do
		self [1 + y * self.Width + x - 1] = columnVector [1 + x]
	end
	
	return self
end

function self:SetRow (y, rowVector)
	for x = 0, self.Width - 1 do
		self [1 + (y - 1) * self.Width + x] = rowVector [1 + x]
	end
	
	return self
end

function self:IsSquare ()
	return self.Width == self.Height
end

function self:Transpose (out)
	if self == out then out = nil end
	
	out = out or GLib.Matrix (self.Height, self.Width)
	
	for y = 0, self.Height - 1 do
		for x = 0, self.Width - 1 do
			out [1 + x * out.Width + y] = self [1 + y * self.Width + x]
		end
	end
	
	return out
end

function self:ToString ()
	local columnWidths = {}
	local matrix = GLib.StringBuilder ()
	
	local elements = {}
	for y = 0, self.Height - 1 do
		for x = 0, self.Width - 1 do
			elements [1 + y * self.Width + x] = tostring (math.abs (self [1 + y * self.Width + x]))
			columnWidths [x] = math.max (columnWidths [x] or 0, #elements [1 + y * self.Width + x])
		end
	end
	
	for y = 0, self.Height - 1 do
		if y > 0 then
			matrix:Append ("\n")
		end
		
		matrix:Append ("[ ")
		
		for x = 0, self.Width - 1 do
			if x > 0 then
				matrix:Append ("    ")
			end
			
			matrix:Append (self [1 + y * self.Width + x] > 0 and " " or "-")
			
			local elementString = elements [1 + y * self.Width + x]
			matrix:Append (string.rep (" ", columnWidths [x] - #elementString))
			matrix:Append (elementString)
		end
		matrix:Append (" ]")
	end
	
	return matrix:ToString ()
end

self.__tostring = self.ToString