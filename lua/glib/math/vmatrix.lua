local self = debug.getregistry ().VMatrix
GLib.VMatrix = {}

function GLib.VMatrix.FromMatrix (matrix)
	return matrix:ToVMatrix ()
end

function self:ToMatrix (out)
	return GLib.Matrix.FromVMatrix (self, out)
end

function self:ToString ()
	return self:ToMatrix ():ToString ()
end

self.__tostring = self.ToString

local self = debug.getregistry ().Vector

function self:ToColumnVector (out)
	out = out or GLib.ColumnVector (3)
	
	out [1] = self.x
	out [2] = self.y
	out [3] = self.z
	
	return out
end

function self:ToRowVector (out)
	out = out or GLib.RowVector (3)
	
	out [1] = self.x
	out [2] = self.y
	out [3] = self.z
	
	return out
end