local self = {}
GLib.Loader.PackFileSystem = GLib.MakeConstructor (self)

function self:ctor ()
	self.Revision = 0
	
	self.Root = {}
end

function self:Read (path)
	local parts = self:NormalizePath (path):Split ("/")
	local folder = self.Root
	for i = 1, #parts do
		folder = folder [parts [i]]
		if not folder then return nil end
	end
	return tostring (folder)
end

function self:Write (path, data)
	self.Revision = self.Revision + 1
	
	local parts = self:NormalizePath (path):Split ("/")
	local folder = self.Root
	for i = 1, #parts - 1 do
		-- Create subdirectory
		folder [parts [i]] = folder [parts [i]] or {}
		folder = folder [parts [i]]
	end
	
	folder [parts [#parts]] = data
end

function self:GetRevision ()
	return self.Revision
end

-- Internal, do not call
function self:GetFolder (path)
	local parts = self:NormalizePath (path):Split ("/")
	local folder = self.Root
	for i = 1, #parts do
		folder = folder [parts [i]]
		if not folder then return nil end
	end
	return folder
end

function self:NormalizePath (path)
	path = path:lower ()
	path = path:gsub ("\\", "/")
	path = path:gsub ("/+", "/")
	if path:sub (1, 1) == "/" then path = path:sub (2) end
	return path
end