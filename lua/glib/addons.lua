GLib.AddCSLuaPackSystem ("GLibAddons")
GLib.AddCSLuaPackFolder ("glib_addons")
GLib.AddCSLuaPackFolderRecursive ("glib_addons/client")

GLib.IncludeDirectory ("glib_addons")
GLib.IncludeDirectory ("glib_addons/" .. (SERVER and "server" or "client"))
