--!strict

local Debris = game:GetService("Debris")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

type SlabRecord = {
	part: BasePart,
	weld: WeldConstraint?,
	durability: number,
	stress: number,
	broken: boolean,
}

local ArenaService = {}
ArenaService.__index = ArenaService

function ArenaService.new()
	local self = setmetatable({}, ArenaService)
	self.model = nil :: Model?
	self.core = nil :: BasePart?
	self.orientation = nil :: AlignOrientation?
	self.slabs = {} :: { SlabRecord }
	self.roundAge = 0
	self.random = Random.new()
	self.spectatorSpawn = CFrame.new(Config.Arena.Center + Vector3.new(0, 8, -82))
	return self
end

local function makePart(name: string, size: Vector3, cframe: CFrame, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

function ArenaService:Destroy()
	if self.model then
		self.model:Destroy()
	end
	self.model = nil
	self.core = nil
	self.orientation = nil
	table.clear(self.slabs)
end

function ArenaService:Build()
	self:Destroy()
	self.roundAge = 0

	local model = Instance.new("Model")
	model.Name = "GeneratedArena"
	model.Parent = workspace
	self.model = model

	local center = Config.Arena.Center

	local voidFloor = makePart(
		"Void",
		Vector3.new(240, 2, 240),
		CFrame.new(center - Vector3.new(0, Config.Round.VoidDepth + 8, 0)),
		model
	)
	voidFloor.Material = Enum.Material.SmoothPlastic
	voidFloor.Color = Color3.fromRGB(12, 10, 18)
	voidFloor.CanCollide = false

	local pedestal = makePart(
		"Pedestal",
		Vector3.new(Config.Arena.PedestalHeight, 9, 9),
		CFrame.new(center - Vector3.new(0, Config.Arena.PedestalHeight / 2 + 2, 0))
			* CFrame.Angles(0, 0, math.rad(90)),
		model
	)
	pedestal.Shape = Enum.PartType.Cylinder
	pedestal.Material = Enum.Material.Slate
	pedestal.Color = Color3.fromRGB(67, 63, 60)
	pedestal.CanCollide = false

	local spectatorDeck = makePart(
		"SpectatorDeck",
		Vector3.new(54, 2, 30),
		CFrame.new(center + Vector3.new(0, 7, -82)),
		model
	)
	spectatorDeck.Material = Enum.Material.Slate
	spectatorDeck.Color = Color3.fromRGB(72, 69, 66)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpectatorSpawn"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = spectatorDeck.CFrame + Vector3.new(0, 2, 0)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Transparency = 0.35
	spawn.Color = Color3.fromRGB(190, 176, 139)
	spawn.Parent = model
	self.spectatorSpawn = spawn.CFrame + Vector3.new(0, 4, 0)

	local core = makePart("ArenaCore", Config.Arena.CoreSize, CFrame.new(center), model)
	core.Transparency = 1
	core.CanCollide = false
	core.CustomPhysicalProperties = PhysicalProperties.new(12, 0.4, 0.2)
	self.core = core

	local coreAttachment = Instance.new("Attachment")
	coreAttachment.Name = "ControlAttachment"
	coreAttachment.Parent = core

	local position = Instance.new("AlignPosition")
	position.Name = "PositionControl"
	position.Mode = Enum.PositionAlignmentMode.OneAttachment
	position.Attachment0 = coreAttachment
	position.Position = center
	position.MaxForce = 1e9
	position.MaxVelocity = 20
	position.Responsiveness = Config.Arena.PositionResponsiveness
	position.RigidityEnabled = false
	position.Parent = core

	local orientation = Instance.new("AlignOrientation")
	orientation.Name = "TiltControl"
	orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	orientation.Attachment0 = coreAttachment
	orientation.CFrame = CFrame.identity
	orientation.MaxTorque = 1e9
	orientation.MaxAngularVelocity = 2.5
	orientation.Responsiveness = Config.Arena.TiltResponsiveness
	orientation.RigidityEnabled = false
	orientation.Parent = core
	self.orientation = orientation

	local gridRadius = Config.Arena.GridRadius
	local slabSize = Config.Arena.SlabSize
	local spacing = slabSize + Config.Arena.SlabGap

	for gridX = -gridRadius, gridRadius do
		for gridZ = -gridRadius, gridRadius do
			local distance = Vector2.new(gridX, gridZ).Magnitude
			if distance <= gridRadius + 0.25 then
				local widthScale = self.random:NextNumber(0.9, 1.08)
				local depthScale = self.random:NextNumber(0.9, 1.08)
				local yOffset = self.random:NextNumber(-0.18, 0.18)
				local yaw = math.rad(self.random:NextNumber(-1.7, 1.7))
				local localPosition = Vector3.new(gridX * spacing, yOffset, gridZ * spacing)

				local slab = makePart(
					string.format("Slab_%d_%d", gridX, gridZ),
					Vector3.new(
						slabSize * widthScale,
						Config.Arena.SlabThickness,
						slabSize * depthScale
					),
					CFrame.new(center + localPosition) * CFrame.Angles(0, yaw, 0),
					model
				)
				slab.Anchored = false
				slab.Material = Enum.Material.Slate
				local shade = self.random:NextInteger(82, 108)
				slab.Color = Color3.fromRGB(shade, shade - 4, shade - 8)
				slab.CustomPhysicalProperties = PhysicalProperties.new(2.2, 0.65, 0.15)

				local weld = Instance.new("WeldConstraint")
				weld.Name = "StructuralWeld"
				weld.Part0 = core
				weld.Part1 = slab
				weld.Parent = slab

				table.insert(self.slabs, {
					part = slab,
					weld = weld,
					durability = self.random:NextNumber(
						Config.Slabs.DurabilityMin,
						Config.Slabs.DurabilityMax
					),
					stress = 0,
					broken = false,
				})
			end
		end
	end

	core.Anchored = false
	core:SetNetworkOwner(nil)
end

function ArenaService:GetSpectatorSpawn(): CFrame
	return self.spectatorSpawn
end

function ArenaService:GetSpawnCFrames(count: number): { CFrame }
	local results = {}
	local radius = math.min(14, 6 + count * 0.7)
	for index = 1, count do
		local angle = ((index - 1) / math.max(count, 1)) * math.pi * 2
		local offset = Vector3.new(math.cos(angle) * radius, 6, math.sin(angle) * radius)
		table.insert(results, CFrame.new(Config.Arena.Center + offset, Config.Arena.Center))
	end
	return results
end

local function getRoot(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

function ArenaService:_setCrackAppearance(record: SlabRecord)
	local fraction = record.stress / record.durability
	if fraction >= 0.82 then
		record.part.Color = Color3.fromRGB(91, 49, 40)
		record.part.Material = Enum.Material.CrackedLava
	elseif fraction >= 0.58 then
		record.part.Color = Color3.fromRGB(112, 85, 65)
		record.part.Material = Enum.Material.Cobblestone
	elseif fraction >= 0.32 then
		record.part.Color = Color3.fromRGB(105, 98, 89)
		record.part.Material = Enum.Material.Rock
	end
end

function ArenaService:_breakSlab(record: SlabRecord)
	if record.broken then
		return
	end
	record.broken = true

	if record.weld then
		record.weld:Destroy()
		record.weld = nil
	end

	local part = record.part
	part.Color = Color3.fromRGB(70, 49, 43)
	part.Material = Enum.Material.Rock
	part.AssemblyLinearVelocity += Vector3.new(
		self.random:NextNumber(-3, 3),
		-Config.Slabs.BreakDownwardSpeed,
		self.random:NextNumber(-3, 3)
	)
	part.AssemblyAngularVelocity = Vector3.new(
		self.random:NextNumber(-2.2, 2.2),
		self.random:NextNumber(-1, 1),
		self.random:NextNumber(-2.2, 2.2)
	)
	Debris:AddItem(part, Config.Slabs.CleanupDelay)
end

function ArenaService:Step(deltaTime: number, activePlayers: { Player })
	if not self.core or not self.orientation then
		return
	end

	self.roundAge += deltaTime

	local totalX = 0
	local totalZ = 0
	local standingRoots = {} :: { BasePart }

	for _, player in activePlayers do
		local root = getRoot(player)
		if root then
			local localPosition = self.core.CFrame:PointToObjectSpace(root.Position)
			local maximumExtent = (Config.Arena.GridRadius + 0.7)
				* (Config.Arena.SlabSize + Config.Arena.SlabGap)
			if math.abs(localPosition.X) <= maximumExtent
				and math.abs(localPosition.Z) <= maximumExtent
				and localPosition.Y > -2
				and localPosition.Y < 10
			then
				totalX += localPosition.X
				totalZ += localPosition.Z
				table.insert(standingRoots, root)
			end
		end
	end

	local maxTilt = Config.Arena.MaxTiltDegrees
	local rollDegrees = math.clamp(
		-totalX * Config.Arena.TiltPerStud,
		-maxTilt,
		maxTilt
	)
	local pitchDegrees = math.clamp(
		totalZ * Config.Arena.TiltPerStud,
		-maxTilt,
		maxTilt
	)

	self.orientation.CFrame = CFrame.Angles(
		math.rad(pitchDegrees),
		0,
		math.rad(rollDegrees)
	)

	if self.roundAge < Config.Slabs.GracePeriod then
		return
	end

	local tiltFraction = math.max(math.abs(rollDegrees), math.abs(pitchDegrees)) / maxTilt

	for _, record in self.slabs do
		if record.broken or not record.part.Parent then
			continue
		end

		local playersOnSlab = 0
		for _, root in standingRoots do
			local slabLocal = record.part.CFrame:PointToObjectSpace(root.Position)
			if math.abs(slabLocal.X) <= record.part.Size.X / 2 + 1.2
				and math.abs(slabLocal.Z) <= record.part.Size.Z / 2 + 1.2
				and slabLocal.Y >= 0
				and slabLocal.Y <= 8
			then
				playersOnSlab += 1
			end
		end

		local stressRate = Config.Slabs.BaseStressPerSecond
			+ tiltFraction * Config.Slabs.TiltStressPerSecond

		if playersOnSlab > 0 then
			stressRate += playersOnSlab * Config.Slabs.PlayerStressPerSecond
			if playersOnSlab > 1 then
				stressRate *= 1
					+ (playersOnSlab - 1) * Config.Slabs.CrowdStressMultiplier
			end
		end

		record.stress += stressRate * deltaTime
		self:_setCrackAppearance(record)

		if record.stress >= record.durability then
			self:_breakSlab(record)
		end
	end
end

function ArenaService:IsBelowVoid(player: Player): boolean
	local root = getRoot(player)
	if not root then
		return true
	end
	return root.Position.Y < Config.Arena.Center.Y - Config.Round.VoidDepth
end

return ArenaService
