function GLib.Enumerator.Join (enumerator1, enumerator2, enumerator3, ...)
	if not enumerator3 then
		local i = 1
		return function ()
			local a, b, c, d = nil
			if i == 1 then
				a, b, c, d = enumerator1 ()
				if a == nil then i = i + 1 end
			end
			if i == 2 then
				a, b, c, d = enumerator2 ()
				if a == nil then i = i + 1 end
			end
			
			return a, b, c, d
		end
	else
		local i = 1
		local enumerators = { enumerator1, enumerator2, enumerator3, ... }
		return function ()
			local a, b, c, d = nil
			
			while a == nil do
				local enumerator = enumerators [i]
				if not enumerator then return nil end
				a, b, c, d = enumerator ()
				if a == nil then i = i + 1 end
			end
			
			return a, b, c, d
		end
	end
end