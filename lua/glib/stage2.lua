if GLib.Stage2 then return end
GLib.Stage2 = true

include ("bitconverter.lua")

include ("colors.lua")

include ("coroutine.lua")
include ("glue.lua")

include ("memoryusagereport.lua")
include ("stringtable.lua")

-- Lua
GLib.Lua = {}
include ("lua/lua.lua")
include ("lua/sessionvariables.lua")
include ("lua/backup.lua")
include ("lua/detours.lua")

include ("lua/stackframe.lua")
include ("lua/stacktrace.lua")
include ("lua/stacktracecache.lua")

include ("lua/operandtype.lua")
include ("lua/opcodeinfo.lua")
include ("lua/opcodes.lua")
include ("lua/opcode.lua")
include ("lua/precedence.lua")
include ("lua/instruction.lua")
include ("lua/loadstore.lua")
include ("lua/framevariable.lua")
include ("lua/functionbytecodereader.lua")
include ("lua/bytecodereader.lua")

-- Unicode
include ("unicode/unicodecategory.lua")
include ("unicode/wordtype.lua")
include ("unicode/utf8.lua")
include ("unicode/unicode.lua")
include ("unicode/unicodecategorytable.lua")
include ("unicode/transliteration.lua")

-- Formatting
include ("formatting/date.lua")
include ("formatting/tableformatter.lua")

-- Serialization
GLib.Serialization = {}
include ("serialization/iserializable.lua")
include ("serialization/serializationinfo.lua")
include ("serialization/customserializationinfo.lua")
include ("serialization/serializableregistry.lua")
include ("serialization/serialization.lua")

-- Networking
include ("networking/networkable.lua")
include ("networking/networkablecontainer.lua")
include ("networking/networkablehost.lua")
include ("networking/subscriberset.lua")

-- Containers
GLib.Containers = {}
include ("containers/binarytree.lua")
include ("containers/binarytreenode.lua")
include ("containers/linkedlist.lua")
include ("containers/linkedlistnode.lua")
include ("containers/list.lua")
include ("containers/queue.lua")
include ("containers/stack.lua")
include ("containers/tree.lua")

-- Networking Containers
include ("containers/networkable/list.lua")

-- Threading
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

include ("protocol/protocol.lua")
include ("protocol/channel.lua")
include ("protocol/endpoint.lua")
include ("protocol/endpointmanager.lua")
include ("protocol/session.lua")

-- Math
include ("math/matrix.lua")
include ("math/vector.lua")
include ("math/columnvector.lua")
include ("math/rowvector.lua")

-- Geometry
GLib.Geometry = {}
include ("geometry/parametricgeometry.lua")
include ("geometry/iparametriccurve.lua")
include ("geometry/iparametricsurface.lua")
include ("geometry/bezierspline.lua")
include ("geometry/quadraticbezierspline.lua")
include ("geometry/cubicbezierspline.lua")
include ("geometry/parametriccurverenderer.lua")

-- Interfaces
GLib.Interfaces = {}
include ("interfaces/interfaces.lua")

-- Addons
include ("addons.lua")