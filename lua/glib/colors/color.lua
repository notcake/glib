GLib.Color = {}

local colorsByName = {}
local colorNames   = {}

function GLib.Color.Clone (color, clone)
	clone = clone or Color (255, 255, 255, 255)
	
	clone.r = color.r
	clone.g = color.g
	clone.b = color.b
	clone.a = color.a
	
	return clone
end

function GLib.Color.FromColor (color, aOrOut, out)
	local a = nil
	
	if isnumber (aOrOut) then
		a = aOrOut
	else
		out = aOrOut
	end
	
	out = GLib.Color.Clone (color, out)
	out.a = a or 255
	
	return out
end

function GLib.Color.FromName (colorName)
	return colorsByName [string.lower (colorName)]
end

function GLib.Color.FromArgb (argb, out)
	out = out or Color (255, 255, 255, 255)
	out.a = math.floor (argb / 0x01000000)
	out.r = math.floor (argb / 0x00010000) % 256
	out.g = math.floor (argb / 0x00000100) % 256
	out.b =             argb               % 256
	
	return out
end

function GLib.Color.FromHtmlColor (htmlColor, aOrOut, out)
	local a = nil
	
	if isnumber (aOrOut) then
		a = aOrOut
	else
		out = aOrOut
	end
	
	local namedColor = GLib.Color.FromName (htmlColor)
	if namedColor then
		if out or a then
			out = out or Color (255, 255, 255, 255)
			GLib.Colors.Clone (namedColor, out)
			out.a = a or 255
		else
			out = namedColor
		end
	else
		-- #RRGGBB
		if string.sub (htmlColor, 1, 1) == "#" then
			htmlColor = string.sub (htmlColor, 2)
		end
		out = GLib.Color.FromRgb (tonumber (htmlColor, 16), a, out)
	end
	return out
end

function GLib.Color.FromRgb (rgb, aOrOut, out)
	local a = nil
	
	if isnumber (aOrOut) then
		a = aOrOut
	else
		out = aOrOut
	end
	
	out = out or Color (255, 255, 255, 255)
	out.a = a or 255
	out.r = math.floor (rgb / 0x00010000) % 256
	out.g = math.floor (rgb / 0x00000100) % 256
	out.b =             rgb               % 256
	
	return out
end

function GLib.Color.GetName (color)
	return colorNames [GLib.Color.ToArgb (color)]
end

function GLib.Color.ToArgb (color)
	return color.a * 0x01000000 + color.r * 0x00010000 + color.g * 0x00000100 + color.b
end

function GLib.Color.ToHtmlColor (color)
	local colorName = GLib.Color.GetName (color)
	if colorName then return string.lower (colorName) end
	
	return string.format ("#%06X", GLib.Color.ToRgb (color))
end

function GLib.Color.ToRgb (color)
	return color.r * 0x00010000 + color.g * 0x00000100 + color.b
end

-- Build indices
for colorName, color in pairs (GLib.Colors) do
	colorsByName [string.lower (colorName)] = color
	colorNames [GLib.Color.ToArgb (color)] = colorName
end