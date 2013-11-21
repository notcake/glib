GLib.Lua.Precedence = GLib.Enum (
	{
		Lowest         = 0,
        Addition       = 1,
        Subtraction    = 2,
        Multiplication = 3,
        Division       = 4,
		Modulo         = 5,
        Exponentiation = 6,
        Atom           = 7
	}
)

local associativePrecedences =
{
	[GLib.Lua.Precedence.Addition] = true,
	[GLib.Lua.Precedence.Multiplication] = true,
}

function GLib.Lua.IsPrecedenceAssociative (precedence)
	return associativePrecedences [precedence] or false
end