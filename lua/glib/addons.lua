GLib.AddCSLuaFolder ("glib_addons")
GLib.AddCSLuaFolder ("glib_addons/client")

GLib.IncludeDirectory ("glib_addons")
GLib.IncludeDirectory ("glib_addons/" .. (SERVER and "server" or "client"))
