local self = {}
GLib.PlayerMonitor = GLib.MakeConstructor (self)

function self:ctor (systemName)
	self.SystemName = systemName

	self.Players = {}           -- Map of Steam Ids to player data
	self.EntitiesToUserIds = {} -- Map of Players to Steam Ids
	self.QueuedPlayers = {}     -- Array of new Players to be processed
	GLib.EventProvider (self)
	
	hook.Add (CLIENT and "OnEntityCreated" or "PlayerInitialSpawn", self.SystemName .. ".PlayerConnected", function (ply)
		if type (ply) == "Player" then
			self.QueuedPlayers [ply] = true
		end
	end)

	hook.Add ("Think", self.SystemName .. ".PlayerConnected", function ()
		-- Check for new players
		for _, ply in ipairs (player.GetAll ()) do
			local steamId = self:GetPlayerSteamId (ply)
			if steamId then
				if not self.QueuedPlayers [ply] and not self.EntitiesToUserIds [ply] then
					self.QueuedPlayers [ply] = true
				end
			end
		end
		
		-- Process new players
		for ply, _ in pairs (self.QueuedPlayers) do
			local steamId = self:GetPlayerSteamId (ply)
			if steamId and
			   steamId ~= "STEAM_ID_PENDING" and 
			   ply:Name () ~= "unconnected" then
				self.QueuedPlayers [ply] = nil
				
				local isLocalPlayer = CLIENT and ply == LocalPlayer () or false
				self.Players [steamId] =
				{
					Player = ply,
					Name = ply:Name ()
				}
				self.EntitiesToUserIds [ply] = steamId
				self:DispatchEvent ("PlayerConnected", ply, steamId, isLocalPlayer)
				if isLocalPlayer then
					self:DispatchEvent ("LocalPlayerConnected", ply, steamId)
				end
			end
		end
	end)

	hook.Add ("EntityRemoved", self.SystemName .. ".PlayerDisconnected", function (ply)
		local steamId = self:GetPlayerSteamId (ply)
		if not steamId then return end
		
		if SERVER then
			self.Players [steamId] = nil
			self.EntitiesToUserIds [ply] = nil
		end
		self:DispatchEvent ("PlayerDisconnected", ply, steamId)
	end)

	for _, ply in ipairs (player.GetAll ()) do
		self.QueuedPlayers [ply] = true
	end

	if type (_G [systemName]) == "table" and
	   type (_G [systemName].AddEventListener) == "function" then
		_G [systemName]:AddEventListener ("Unloaded", function ()
			self:dtor ()
		end)
	end
end

function self:dtor ()
	hook.Remove (CLIENT and "OnEntityCreated" or "PlayerInitialSpawn", self.SystemName .. ".PlayerConnected")
	hook.Remove ("Think", self.SystemName .. ".PlayerConnected")
	hook.Remove ("EntityRemoved", self.SystemName .. ".PlayerDisconnected")
end

--[[
	PlayerMonitor:GetPlayerEnumerator
		Returns: ()->(userId, Player player)
		
		Enumerates connected players.
]]
function self:GetPlayerEnumerator ()
	local next, tbl, key = pairs (self.Players)
	return function ()
		key = next (tbl, key)
		return key, (key and tbl [key].Player:IsValid () and tbl [key].Player or nil)
	end
end

function self:GetPlayerSteamId (ply)
	if self.EntitiesToUserIds [ply] then return self.EntitiesToUserIds [ply] end

	if not ply then return nil end
	if not ply:IsValid () then return nil end
	if type (ply.SteamID) ~= "function" then return nil end
	
	local steamId = ply:SteamID ()
	
	local isLocalPlayer = CLIENT and ply == LocalPlayer () or false
	if game.SinglePlayer () and isLocalPlayer then steamId = "STEAM_0:0:0" end
	if steamId == "NULL" then steamId = "BOT" end
	
	return steamId
end

function self:GetUserEntity (userId)
	local userEntry = self.Players [userId]
	if not userEntry then return nil end
	
	return userEntry.Player:IsValid () and userEntry.Player or nil
end

--[[
	PlayerMonitor:GetUserEnumerator ()
		Returns: ()->userId userEnumerator
		
		Enumerates user ids.
]]
function self:GetUserEnumerator ()
	local next, tbl, key = pairs (self.Players)
	return function ()
		key = next (tbl, key)
		return key
	end
end

function self:GetUserName (userId)
	local userEntry = self.Players [userId]
	if not userEntry then return userId end
	if userEntry.Player:IsValid () then
		return userEntry.Player:Name ()
	end
	
	return userEntry.Name
end