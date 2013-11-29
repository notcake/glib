local self = {}
GLib.Geometry.CubicBezierSpline = GLib.MakeConstructor (self, GLib.Geometry.IParametricCurve)

GLib.Geometry.CubicBezierMatrix = GLib.Matrix (4, 4,
	-1,  3, -3,  1,
	 3, -6,  3,  0,
	-3,  3,  0,  0,
	 1,  0,  0,  0
)

function self:ctor (dimensions)
	dimensions = dimensions or 3
	
	self.Dimensions = dimensions
	
	self.BezierMatrix = GLib.Geometry.CubicBezierMatrix
	self.GeometryMatrix = GLib.Matrix (self.Dimensions, 4)
	
	self.CMatrix = GLib.Matrix (4, 4)
	self.CMatrixValid = false
end

function self:GetCMatrix ()
	if not self.CMatrixValid then
		self.BezierMatrix:Multiply (self.GeometryMatrix, self.CMatrix)
		self.CMatrixValid = true
	end
	
	return self.CMatrix
end

function self:GetControlPoint (i, out)
	out = out or GLib.RowVector (self:GetDimensions ())
	
	return self.GeometryMatrix:GetRow (i, out)
end

function self:GetDegree ()
	return 3
end

function self:GetDimensions ()
	return self.Dimensions
end

function self:SetControlPoint (i, vector)
	self.GeometryMatrix:SetRow (i, vector)
	self.CMatrixValid = false
end

function self:Evaluate (t, out)
	if type (t) ~= "table" then
		t = GLib.RowVector (4, t * t * t, t * t, t, 1)
	end
	
	out = out or GLib.RowVector ()
	return t:Multiply (self:GetCMatrix (), out)
end

function self:EvaluateTangent (t, out)
	if type (t) ~= "table" then
		t = GLib.RowVector (4, 3 * t * t, 2 * t, 1, 0)
	end
	
	out = out or GLib.RowVector ()
	return t:Multiply (self:GetCMatrix (), out)
end