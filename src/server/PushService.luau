--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local PushService = {}
PushService.__index = PushService

local function getLivingRoot(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return nil
	end
	return root
end

function PushService.new(pushRemote: RemoteEvent, isActive: (Player) -> boolean)
	local self = setmetatable({}, PushService)
	self.pushRemote = pushRemote
	self.isActive = isActive
	self.lastPush = {} :: { [Player]: number }

	pushRemote.OnServerEvent:Connect(function(player)
		self:_onPushRequested(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self.lastPush[player] = nil
	end)

	return self
end

function PushService:_findTarget(attacker: Player, attackerRoot: BasePart): BasePart?
	local bestTarget = nil
	local bestDistance = math.huge
	local look = attackerRoot.CFrame.LookVector

	for _, candidate in Players:GetPlayers() do
		if candidate == attacker or not self.isActive(candidate) then
			continue
		end

		local targetRoot = getLivingRoot(candidate)
		if not targetRoot then
			continue
		end

		local offset = targetRoot.Position - attackerRoot.Position
		local distance = offset.Magnitude
		if distance <= 0.01 or distance > Config.Push.Range then
			continue
		end

		local facingDot = look:Dot(offset.Unit)
		if facingDot < Config.Push.MinimumFacingDot then
			continue
		end

		if distance < bestDistance then
			bestDistance = distance
			bestTarget = targetRoot
		end
	end

	return bestTarget
end

function PushService:_onPushRequested(player: Player)
	if not self.isActive(player) then
		return
	end

	local now = os.clock()
	local previous = self.lastPush[player] or 0
	if now - previous < Config.Push.Cooldown then
		return
	end

	local attackerRoot = getLivingRoot(player)
	if not attackerRoot then
		return
	end

	local targetRoot = self:_findTarget(player, attackerRoot)
	if not targetRoot then
		return
	end

	self.lastPush[player] = now

	local flatOffset = targetRoot.Position - attackerRoot.Position
	flatOffset = Vector3.new(flatOffset.X, 0, flatOffset.Z)
	if flatOffset.Magnitude < 0.01 then
		flatOffset = Vector3.new(attackerRoot.CFrame.LookVector.X, 0, attackerRoot.CFrame.LookVector.Z)
	end

	local direction = flatOffset.Unit
	local targetVelocityChange = direction * Config.Push.Impulse
		+ Vector3.new(0, Config.Push.UpwardImpulse, 0)
	targetRoot:ApplyImpulse(targetVelocityChange * targetRoot.AssemblyMass)

	local recoil = -direction * Config.Push.SelfRecoil
	attackerRoot:ApplyImpulse(recoil * attackerRoot.AssemblyMass)

	self.pushRemote:FireAllClients("Impact", attackerRoot.Position, targetRoot.Position)
end

return PushService
