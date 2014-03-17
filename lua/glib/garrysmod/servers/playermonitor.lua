local self = {}
GLib.PlayerMonitor = GLib.MakeConstructor (self, GLib.IPlayerMonitor)

--[[
	Events:
		LocalPlayerConnected (Player ply, userId)
			Fired when the local client's player entity has been created.
		PlayerConnected (Player ply, userId, isLocalPlayer)
			Fired when a player has connected and has a player entity.
		PlayerDisconnected (Player ply, userId)
			Fired when a player has disconnected.
]]

function self:ctor ()
	self.QueuedPlayers = {} -- Array of new Players to be processed
	
	self.EntriesBySteamId = {} -- Map<SteamId, Set<Entry>>
	self.EntriesByUserId  = {}
	self.NameCache = {}
	
	-- Players have to be queued because they might not have their steam IDs available yet.
	hook.Add (CLIENT and "OnEntityCreated" or "PlayerInitialSpawn", "GLib.PlayerMonitor.PlayerConnected",
		function (ply)
			if not ply:IsPlayer () then return end
			
			self.QueuedPlayers [ply] = true
		end
	)
	
	hook.Add ("Think", "GLib.PlayerMonitor.ProcessQueue",
		function ()
			-- Check for new players.
			-- This really is needed (did tests).
			for _, ply in ipairs (player.GetAll ()) do
				if not self.EntriesByUserId [ply:UserID ()] and
				   not self.QueuedPlayers [ply] and
				   GLib.GetPlayerId (ply) then
					self.QueuedPlayers [ply] = true
				end
			end
			
			-- Process new players
			for ply, _ in pairs (self.QueuedPlayers) do
				local userId = GLib.GetPlayerId (ply)
				if not ply:IsValid () then
					self.QueuedPlayers [ply] = nil
					GLib.Error ("PlayerMonitor : No idea what just happened (" .. tostring (ply) .. ").")
				elseif userId and 
				       userId ~= "STEAM_ID_PENDING" then
					self.QueuedPlayers [ply] = nil
					
					-- Add entry
					local entry = GLib.PlayerMonitorEntry (ply)
					self.EntriesBySteamId [userId] = self.EntriesBySteamId [userId] or {}
					self.EntriesBySteamId [userId] [entry] = true
					self.EntriesByUserId [entry:GetUserId ()] = entry
					self.NameCache [userId] = ply:Name ()
					
					-- Dispatch events
					local isLocalPlayer = CLIENT and ply == LocalPlayer () or false
					self:DispatchEvent ("PlayerConnected", ply, userId, isLocalPlayer)
					
					if isLocalPlayer then
						self:DispatchEvent ("LocalPlayerConnected", ply, userId)
					end
				end
			end
		end
	)
	
	gameevent.Listen ("player_disconnect")
	hook.Add ("player_disconnect", "GLib.PlayerMonitor.PlayerDisconnected",
		function (data)
			local userId  = data.userid
			local entry = self.EntriesByUserId [userId]
			
			if not entry then return end
			
			-- Remove entry
			self.EntriesByUserId [userId] = nil
			self.EntriesBySteamId [entry:GetSteamId ()] [entry] = nil
			
			if not next (self.EntriesBySteamId [entry:GetSteamId ()]) then
				self.EntriesBySteamId [entry:GetSteamId ()] = nil
			end
			
			-- Dispatch event
			self:DispatchEvent ("PlayerDisconnected", entry:GetPlayer (), entry:GetSteamId ())
		end
	)
	
	-- Queue existing players
	for _, ply in ipairs (player.GetAll ()) do
		self.QueuedPlayers [ply] = true
	end
end

function self:dtor ()
	hook.Remove (CLIENT and "OnEntityCreated" or "PlayerInitialSpawn", "GLib.PlayerMonitor.PlayerConnected")
	hook.Remove ("Think", "GLib.PlayerMonitor.ProcessQueue")
	hook.Remove ("player_disconnect", "GLib.PlayerMonitor.PlayerDisconnected")
end

-- Enumerates connected players.
-- Returns: () -> (userId, Player player)
function self:GetPlayerEnumerator ()
	local next, tbl, key = pairs (self.EntriesByUserId)
	return function ()
		key = next (tbl, key)
		if not key then return nil, nil end
		
		local entry = self.EntriesByUserId [key]
		return entry:GetSteamId (), entry:GetPlayer ()
	end
end

function self:GetUserEntity (userId)
	if not self.EntriesBySteamId [userId] then return nil end
	
	for entry, _ in pairs (self.EntriesBySteamId [userId]) do
		return entry:GetPlayer ()
	end
	
	return nil
end

function self:GetUserEntities (userId)
	if not self.EntriesBySteamId [userId] then return nil end
	
	local entities = {}
	for entry, _ in pairs (self.EntriesBySteamId [userId]) do
		entities [#entities + 1] = entry:GetPlayer ()
	end
	
	return entities
end

-- Enumerates user ids.
-- Returns: () -> userId
function self:GetUserEnumerator ()
	local next, tbl, key = pairs (self.EntriesBySteamId)
	return function ()
		key = next (tbl, key)
		return key
	end
end

function self:GetUserName (userId)
	local userEntity = self:GetUserEntity (userId)
	
	if userEntity and userEntity:IsValid () then
		self.NameCache [userId] = userEntity:Name ()
		return userEntity:Name ()
	end
	
	return self.NameCache [userId] or userId
end

function self:__call (...)
	return GLib.PlayerMonitorProxy (self, ...)
end

GLib.PlayerMonitor = GLib.PlayerMonitor ()