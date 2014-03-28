GLib.Color = {}

local colorsByName = {}
local colorNames   = {}

function GLib.Color.FromName (colorName)
	return colorsByName [string.lower (colorName)]
end

function GLib.Color.FromArgb (argb)
	local a = math.floor (argb / 0x01000000)
	local r = math.floor (argb / 0x00010000) % 256
	local g = math.floor (argb / 0x00000100) % 256
	local b =             argb               % 256
	
	return Color (r, g, b, a)
end

function GLib.Color.GetName (color)
	return colorNames [GLib.Color.ToArgb (color)]
end

function GLib.Color.ToArgb (color)
	return color.a * 0x01000000 + color.r * 0x00010000 + color.g * 0x00000100 + color.b
end

-- Build indices
for colorName, color in pairs (GLib.Colors) do
	colorsByName [string.lower (colorName)] = color
	colorNames [GLib.Color.ToArgb (color)] = colorName
end