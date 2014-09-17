local self = {}
GLib.Enumerator.EnumerableAdapter = GLib.MakeConstructor (self)

function self:ctor (table, enumeratorFactory)
	self.Table = table
	self.EnumeratorFactory = enumeratorFactory
end

function self:GetEnumerator ()
	return self.EnumeratorFactory (self.Table)
end