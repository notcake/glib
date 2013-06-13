if GLib.Stage2 then return end
GLib.Stage2 = true

include ("colors.lua")

include ("coroutine.lua")
include ("glue.lua")

include ("memoryusagereport.lua")

include ("unicode/unicodecategory.lua")
include ("unicode/wordtype.lua")
include ("unicode/utf8.lua")
include ("unicode/unicode.lua")
include ("unicode/unicodecategorytable.lua")
include ("unicode/transliteration.lua")

GLib.Containers = {}
include ("containers/binarytree.lua")
include ("containers/binarytreenode.lua")
include ("containers/linkedlist.lua")
include ("containers/linkedlistnode.lua")
include ("containers/list.lua")
include ("containers/queue.lua")
include ("containers/stack.lua")
include ("containers/tree.lua")

GLib.Threading = {}
include ("threading/threading.lua")
include ("threading/thread.lua")
include ("threading/threadstate.lua")

include ("net/net.lua")
include ("net/datatype.lua")
include ("net/outbuffer.lua")
include ("net/netdispatcher.lua")
include ("net/usermessagedispatcher.lua")
include ("net/netinbuffer.lua")
include ("net/usermessageinbuffer.lua")
include ("net/stringtable.lua")

include ("protocol/protocol.lua")
include ("protocol/channel.lua")
include ("protocol/endpoint.lua")
include ("protocol/endpointmanager.lua")
include ("protocol/session.lua")