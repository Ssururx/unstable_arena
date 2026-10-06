--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local RoundService = {}
RoundService.__index = RoundService

local function getHumanoidAndRoot(player: Player): (Humanoid?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and not root:IsA("BasePart") then
		root = nil
	end
	return humanoid, root :: BasePart?
end

local function ensureCharacter(player: Player): (Model?, BasePart?)
	local humanoid, root = getHumanoidAndRoot(player)
	if humanoid and humanoid.Health > 0 and root then
		return player.Character, root
	end

	player:LoadCharacter()
	local character = player.Character or player.CharacterAdded:Wait()
	local newRoot = character:WaitForChild("HumanoidRootPart", 8)
	if newRoot and newRoot:IsA("BasePart") then
		return character, newRoot
	end
	return character, nil
end

function RoundService.new(arena, stateRemote: RemoteEvent)
	local self = setmetatable({}, RoundService)
	self.arena = arena
	self.stateRemote = stateRemote
	self.active = {} :: { [Player]: boolean }
	self.phase = "Booting"
	self.roundNumber = 0
	return self
end

function RoundService:IsActive(player: Player): boolean
	return self.active[player] == true
end

function RoundService:_activeList(): { Player }
	local result = {}
	for player in self.active do
		if player.Parent == Players then
			table.insert(result, player)
		end
	end
	return result
end

function RoundService:_broadcast(phase: string, timeRemaining: number, message: string?)
	self.phase = phase
	self.stateRemote:FireAllClients({
		phase = phase,
		timeRemaining = math.max(0, math.ceil(timeRemaining)),
		remaining = #self:_activeList(),
		message = message,
	})
end

function RoundService:_sendToSpectatorDeck(player: Player)
	player:SetAttribute("InRound", false)
	local character, root = ensureCharacter(player)
	if not character or not root then
		return
	end

	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	character:PivotTo(self.arena:GetSpectatorSpawn())
end

function RoundService:_eliminate(player: Player)
	if not self.active[player] then
		return
	end
	self.active[player] = nil
	task.spawn(function()
		self:_sendToSpectatorDeck(player)
	end)
end

function RoundService:_preparePlayers(): { Player }
	local contestants = Players:GetPlayers()
	local spawns = self.arena:GetSpawnCFrames(#contestants)
	table.clear(self.active)

	for index, player in contestants do
		local character, root = ensureCharacter(player)
		if character and root then
			self.active[player] = true
			player:SetAttribute("InRound", true)
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			character:PivotTo(spawns[index])
		end
	end

	return contestants
end

function RoundService:_waitForPlayers()
	while #Players:GetPlayers() < Config.Round.MinimumPlayers do
		self:_broadcast("Waiting", 0, "Waiting for a player")
		task.wait(1)
	end
end

function RoundService:_timedPhase(phase: string, duration: number, message: string?)
	local finishAt = os.clock() + duration
	local lastSecond = -1
	while os.clock() < finishAt do
		local remaining = math.ceil(finishAt - os.clock())
		if remaining ~= lastSecond then
			lastSecond = remaining
			self:_broadcast(phase, remaining, message)
		end
		task.wait(0.1)
	end
end

function RoundService:_playRound()
	self.roundNumber += 1
	self.arena:Build()
	local contestants = self:_preparePlayers()
	if #contestants == 0 then
		return
	end

	self:_timedPhase("Countdown", Config.Round.Countdown, "Balance yourself")
	self:_broadcast("Live", Config.Round.Duration, "Stay on the platform")

	local startedAt = os.clock()
	local previousClock = startedAt
	local lastSecond = -1
	local initialCount = #self:_activeList()

	while true do
		RunService.Heartbeat:Wait()
		local now = os.clock()
		local deltaTime = math.min(now - previousClock, 0.1)
		previousClock = now

		local activePlayers = self:_activeList()
		self.arena:Step(deltaTime, activePlayers)

		for _, player in activePlayers do
			local humanoid, root = getHumanoidAndRoot(player)
			if not humanoid or humanoid.Health <= 0 or not root or self.arena:IsBelowVoid(player) then
				self:_eliminate(player)
			end
		end

		local elapsed = now - startedAt
		local remainingTime = math.max(0, Config.Round.Duration - elapsed)
		local remainingPlayers = #self:_activeList()
		local wholeSecond = math.ceil(remainingTime)

		if wholeSecond ~= lastSecond then
			lastSecond = wholeSecond
			self:_broadcast("Live", wholeSecond, "Stay on the platform")
		end

		if remainingTime <= 0 or remainingPlayers == 0 then
			break
		end

		if initialCount > 1 and remainingPlayers <= 1 then
			break
		end
	end

	local survivors = self:_activeList()
	if #survivors == 1 then
		local winner = survivors[1]
		winner:SetAttribute("PrototypeWins", (winner:GetAttribute("PrototypeWins") or 0) + 1)
		self:_broadcast("Finished", 5, winner.DisplayName .. " survived!")
	elseif #survivors > 1 then
		self:_broadcast("Finished", 5, tostring(#survivors) .. " players survived")
	else
		self:_broadcast("Finished", 5, "The arena won")
	end

	task.wait(5)

	for _, player in Players:GetPlayers() do
		self.active[player] = nil
		task.spawn(function()
			self:_sendToSpectatorDeck(player)
		end)
	end
end

function RoundService:Run()
	Players.PlayerRemoving:Connect(function(player)
		self.active[player] = nil
	end)

	Players.PlayerAdded:Connect(function(player)
		player:SetAttribute("InRound", false)
	end)

	while true do
		self:_waitForPlayers()
		self:_timedPhase("Intermission", Config.Round.Intermission, "Next collapse incoming")
		if #Players:GetPlayers() >= Config.Round.MinimumPlayers then
			self:_playRound()
		end
	end
end

return RoundService
