function GLib.Enumerator.ArrayEnumerator (tbl)
	local i = 0
	return function ()
		i = i + 1
		return tbl [i]
	end
end

function GLib.Enumerator.KeyEnumerator (tbl)
	local next, tbl, key = pairs (tbl)
	return function ()
		key = next (tbl, key)
		return key
	end
end

function GLib.Enumerator.ValueEnumerator (tbl)
	local next, tbl, key = pairs (tbl)
	return function ()
		key = next (tbl, key)
		return tbl [key]
	end
end

function GLib.Enumerator.KeyValueEnumerator (tbl)
	local next, tbl, key = pairs (tbl)
	return function ()
		key = next (tbl, key)
		return key, tbl [key]
	end
end

function GLib.Enumerator.ValueKeyEnumerator (tbl)
	local next, tbl, key = pairs (tbl)
	return function ()
		key = next (tbl, key)
		return tbl [key], key
	end
end

GLib.ArrayEnumerator    = GLib.Enumerator.ArrayEnumerator
GLib.KeyEnumerator      = GLib.Enumerator.KeyEnumerator
GLib.ValueEnumerator    = GLib.Enumerator.ValueEnumerator
GLib.KeyValueEnumerator = GLib.Enumerator.KeyValueEnumerator
GLib.ValueKeyEnumerator = GLib.Enumerator.ValueKeyEnumerator