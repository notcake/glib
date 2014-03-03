local self = debug.getregistry ().VMatrix
GLib.VMatrix = {}

function GLib.VMatrix.FromMatrix (matrix)
	return matrix:ToVMatrix ()
end

function self:ToMatrix ()
	return GLib.Matrix.FromVMatrix (self)
end

function self:ToString ()
	return self:ToMatrix ():ToString ()
end

self.__tostring = self.ToString