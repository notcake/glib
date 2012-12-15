local self = {}
GLib.Loader.Networker = GLib.MakeConstructor (self)

if SERVER then
	util.AddNetworkString ("glib_pack")
end

function self:ctor ()
	self.NextOutboundStreamId = 0
	
	self.OutboundStreams = {}
	self.InboundStreams  = {}
	
	self.LastTickTime = SysTime ()
	
	net.Receive ("glib_pack",
		function (_, ply)
			if SERVER and not ply:IsAdmin () then return end
			
			local inBufferLength = net.ReadUInt (32)
			local inBuffer = GLib.StringInBuffer (net.ReadData (inBufferLength))
			
			local newStream = inBuffer:Boolean ()
			local streamId = tostring (inBuffer:UInt32 ())
			
			if SERVER and ply then
				streamId = ply:SteamID () .. streamId
			end
			
			local streamEntry = self.InboundStreams [streamId]
			if newStream then
				streamEntry =
				{
					Id = streamId,
					DestinationId = GLib.GetLocalId ()
				}
				streamEntry.ExecutionTarget = inBuffer:String ()
				streamEntry.DisplayName     = inBuffer:String ()
				streamEntry.Data            = {}
				
				streamEntry.Length          = inBuffer:UInt32 ()
				streamEntry.ChunkSize       = inBuffer:UInt32 ()
				streamEntry.ChunkCount      = math.ceil (streamEntry.Length / streamEntry.ChunkSize)
				streamEntry.NextChunk       = 1
				self.InboundStreams [streamId] = streamEntry
			end
			if not streamEntry then return end
			
			-- Read chunk
			streamEntry.Data [#streamEntry.Data + 1] = inBuffer:LongString ()
			streamEntry.NextChunk = streamEntry.NextChunk + 1
			
			if streamEntry.NextChunk > streamEntry.ChunkCount then
				-- Finished
				streamEntry.Data = table.concat (streamEntry.Data)
				
				local packFileSystem = GLib.Loader.PackFileSystem ()
				packFileSystem:SetName (streamEntry.DisplayName)
				local startTime = SysTime ()
				packFileSystem:Deserialize (streamEntry.Data,
					function ()
						MsgN ("GLib : Deserializing pack file \"" .. packFileSystem:GetName () .. "\" took " .. GLib.FormatDuration (SysTime () - startTime) .. " (" .. packFileSystem:GetFileCount () .. " total files, " .. GLib.FormatFileSize (#streamEntry.Data) .. ").")
						GLib.Loader.RunPackFile (streamEntry.ExecutionTarget, packFileSystem)
					end
				)
				
				self.InboundStreams [streamId] = nil
			end
		end
	)
end

function self:dtor ()
	hook.Remove ("Tick", "GLib.Loader.OutboundStreamer")
end

function self:AllocateOutboundStreamId (packData)
	local outboundStreamId = tonumber (util.CRC (packData)) + self.NextOutboundStreamId
	self.NextOutboundStreamId = self.NextOutboundStreamId + 1
	return outboundStreamId
end

function self:StreamPack (destinationId, executionTarget, packData, displayName)
	local outboundStreamId = self:AllocateOutboundStreamId (packData)
	
	local length     = #packData
	local chunkSize  = 32768
	local chunkCount = math.ceil (length / chunkSize)
	self.OutboundStreams [outboundStreamId] =
	{
		Id              = outboundStreamId,
		DestinationId   = destinationId,
		ExecutionTarget = executionTarget,
		Started         = false,
		DisplayName     = displayName or tostring (outboundStreamId),
		Data            = packData,
		
		Length          = length,
		ChunkSize       = chunkSize,
		ChunkCount      = chunkCount,
		
		NextChunk       = 1
	}
	
	self:StartOutboundStreamer ()
end

-- Internal, do not call
function self:StartOutboundStreamer ()
	hook.Add ("Tick", "GLib.Loader.OutboundStreamer",
		function ()
			if not next (self.OutboundStreams) then
				hook.Remove ("Tick", "GLib.Loader.OutboundStreamer")
				return
			end
			
			if SysTime () - self.LastTickTime < 0.05 then return end
			self.LastTickTime = SysTime ()
			
			for streamId, streamEntry in pairs (self.OutboundStreams) do
				local destinationId = streamEntry.DestinationId
				if destinationId ~= GLib.GetServerId () and
				   destinationId ~= GLib.GetEveryoneId () and
				   not GLib.Net.PlayerMonitor:GetUserEntity (destinationId) then
					-- Destination player disconnected
					self.OutboundStreams [streamId] = nil
					destinationId = nil
				end
				if destinationId then
					local outBuffer = GLib.StringOutBuffer ()
					outBuffer:Boolean (not streamEntry.Started)
					outBuffer:UInt32 (streamEntry.Id)
					
					if not streamEntry.Started then
						-- Generate initial packet
						streamEntry.Started = true
						
						outBuffer:String (streamEntry.ExecutionTarget)
						outBuffer:String (streamEntry.DisplayName)
						outBuffer:UInt32 (streamEntry.Length)
						outBuffer:UInt32 (streamEntry.ChunkSize)
					end
					
					-- Include the next chunk
					local chunkStart = (streamEntry.NextChunk - 1) * streamEntry.ChunkSize + 1
					local chunkEnd   = streamEntry.NextChunk * streamEntry.ChunkSize
					outBuffer:LongString (string.sub (streamEntry.Data, chunkStart, chunkEnd))
					
					streamEntry.NextChunk = streamEntry.NextChunk + 1
					
					-- Send net message
					net.Start ("glib_pack")
					net.WriteUInt (#outBuffer:GetString (), 32)
					net.WriteData (outBuffer:GetString (), #outBuffer:GetString ())
					if destinationId == GLib.GetServerId () then
						net.SendToServer ()
					elseif destinationId == GLib.GetEveryoneId () then
						net.Broadcast ()
					else
						net.Send (GLib.Net.PlayerMonitor:GetUserEntity (destinationId))
					end
					
					if streamEntry.NextChunk > streamEntry.ChunkCount then
						-- Finished sending stream, remove it
						self.OutboundStreams [streamId] = nil
					end
				end
			end
		end
	)
end

GLib.Loader.Networker = GLib.Loader.Networker ()