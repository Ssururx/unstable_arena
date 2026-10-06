--!nonstrict
local Debris = game:GetService("Debris")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Rules = require(game:GetService("ReplicatedStorage").Shared.Rules)
local U = require(script.Parent.Util)
local Arena = {}
Arena.__index = Arena

function Arena.new(fx)
	local self = setmetatable({ fx = fx, slabs = {}, age = 0, rng = Random.new(), dummies = {} }, Arena)
	self:BuildLobby()
	return self
end

function Arena:BuildLobby()
	local world = Instance.new("Model")
	world.Name = "UnstableArenaWorld"; world.Parent = workspace
	self.world = world
	local center = Config.Arena.Center
	local stone = Color3.fromRGB(83, 82, 88)
	-- Permanent spectator ring. Never destroyed during round resets.
	for i = 0, 31 do
		local a = i / 32 * math.pi * 2
		local cf = CFrame.new(center + Vector3.new(math.sin(a)*76, 5, math.cos(a)*76)) * CFrame.Angles(0, a, 0)
		U.part(world, "SpectatorWalkway", Vector3.new(15.2, 2, 14), cf, stone)
		U.part(world, "InnerRail", Vector3.new(15.2, 3, 0.7), cf*CFrame.new(0, 2.3, -6.7), stone)
		U.part(world, "OuterRail", Vector3.new(15.2, 3, 0.7), cf*CFrame.new(0, 2.3, 6.7), stone)
		if i % 2 == 0 then
			U.part(world, "Column", Vector3.new(4, 20, 4), cf*CFrame.new(0, 10, 9), stone)
			local cap = U.part(world, "ColumnLight", Vector3.new(4.8, 0.5, 4.8), cf*CFrame.new(0, 20, 9), Color3.fromRGB(255, 201, 122), Enum.Material.Neon)
			cap.CanCollide = false
		end
	end
	local deck = U.part(world, "LobbyDeck", Vector3.new(48, 2, 28), CFrame.new(center + Vector3.new(0, 5, -78)), stone)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"; spawn.Size = Vector3.new(6, 1, 6); spawn.Anchored = true
	spawn.CFrame = deck.CFrame*CFrame.new(0, 1.5, 6); spawn.Transparency = 1
	spawn.Neutral = true; spawn.Duration = 0; spawn.Parent = world
	self.spawn = spawn.CFrame*CFrame.new(0, 4, 0)
	local sign = U.part(world, "WelcomeSign", Vector3.new(30, 8, 1), deck.CFrame*CFrame.new(0, 8, -13), Color3.fromRGB(30, 30, 39))
	local board = Instance.new("SurfaceGui"); board.Face = Enum.NormalId.Back; board.CanvasSize = Vector2.new(900, 240); board.Parent = sign
	local label = Instance.new("TextLabel"); label.Size = UDim2.fromScale(1, 1); label.BackgroundTransparency = 1
	label.Text = "UNSTABLE ARENA\nPUSH • BALANCE • SURVIVE"; label.TextColor3 = Color3.fromRGB(248, 215, 157)
	label.TextSize = 52; label.Font = Enum.Font.GothamBold; label.Parent = board
	for i = 1, 2 do
		local home = deck.CFrame*CFrame.new(if i == 1 then -12 else 12, 5, 0)
		self:MakeDummy(home)
	end
	local cylinder = U.part(world, "CentralSupport", Vector3.new(28, 9, 9),
		CFrame.new(center-Vector3.new(0, 17, 0))*CFrame.Angles(0,0,math.pi/2), stone)
	cylinder.Shape = Enum.PartType.Cylinder; cylinder.CanCollide = false
	local pit = U.part(world, "Pit", Vector3.new(160, 2, 160), CFrame.new(0, 0, 0), Color3.fromRGB(10, 13, 20))
	pit.CanCollide = false
end

function Arena:MakeDummy(home)
	local rig = Instance.new("Model"); rig.Name = "PracticeDummy"; rig.Parent = self.world
	local root = U.part(rig, "HumanoidRootPart", Vector3.new(2,2,1), home, Color3.fromRGB(180,150,100))
	root.Transparency = 1; root.CanCollide = false
	local torso = U.part(rig, "Torso", Vector3.new(2.5,2.5,1.5), home, Color3.fromRGB(157,121,73), Enum.Material.Wood)
	U.weld(root, torso)
	local head = U.part(rig, "Head", Vector3.new(1.5,1.5,1.5), home*CFrame.new(0,2,0), Color3.fromRGB(228,197,148), Enum.Material.Wood)
	U.weld(root, head)
	for _, x in {-0.65, 0.65} do
		local leg = U.part(rig, "Leg", Vector3.new(1,2,1), home*CFrame.new(x,-2,0), torso.Color, Enum.Material.Wood)
		U.weld(root, leg)
	end
	local h = Instance.new("Humanoid"); h.RequiresNeck = false; h.BreakJointsOnDeath = false
	h.MaxHealth = 100000; h.Health = 100000; h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	h.Parent = rig
	rig.PrimaryPart = root; root.Anchored = false; root:SetNetworkOwner(nil)
	rig:SetAttribute("Practice", true); U.label(head, "PRACTICE • PUSH ME")
	table.insert(self.dummies, { model = rig, home = home, movedAt = nil })
end

function Arena:StepPractice()
	for _, d in self.dummies do
		local root, hum = U.root(d.model)
		if root then
			local moved = (root.Position - d.home.Position).Magnitude > 6
			if moved and not d.movedAt then d.movedAt = os.clock() end
			if root.Position.Y < 20 or (d.movedAt and os.clock()-d.movedAt > 2.5) then
				d.model:PivotTo(d.home); root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero; hum.PlatformStand = false; d.movedAt = nil
			end
		end
	end
end

function Arena:Build(map)
	if self.model then self.model:Destroy() end
	table.clear(self.slabs); self.age = 0; self.map = map
	local model = Instance.new("Model"); model.Name = "RoundArena"; model.Parent = self.world; self.model = model
	local center = Config.Arena.Center
	local core = U.part(model, "Core", Vector3.new(3,2,3), CFrame.new(center))
	core.Transparency = 1; core.CanCollide = false; core.CanQuery = false
	core.RootPriority = 127; self.core = core
	local attachment = Instance.new("Attachment"); attachment.Parent = core
	local position = Instance.new("AlignPosition"); position.Mode = Enum.PositionAlignmentMode.OneAttachment
	position.Attachment0 = attachment; position.Position = center; position.MaxForce = 1e9
	position.ApplyAtCenterOfMass = true; position.Responsiveness = 70; position.MaxVelocity = 30; position.Parent = core
	local orientation = Instance.new("AlignOrientation"); orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	orientation.Attachment0 = attachment; orientation.MaxTorque = 1e9
	orientation.MaxAngularVelocity = Config.Arena.AngularSpeed; orientation.Responsiveness = Config.Arena.Response
	orientation.CFrame = CFrame.identity; orientation.Parent = core; self.orientation = orientation

	for x = -2, 2 do
		for z = -2, 2 do
			if math.abs(x) == 2 and math.abs(z) == 2 then continue end
			local cf = CFrame.new(center + Vector3.new(x*10, self.rng:NextNumber(-0.14,0.14), z*10))
			local slab = U.part(model, "Slab", Vector3.new(self.rng:NextNumber(9.3,9.7),2,self.rng:NextNumber(9.3,9.7)), cf, map.Color, map.Material)
			slab.CustomPhysicalProperties = PhysicalProperties.new(1.5, 0.42, 0.08)
			local weld = U.weld(core, slab)
			local record = { part = slab, weld = weld, stress = 0, broken = false, warningAt = nil,
				durability = self.rng:NextNumber(Config.Slabs.DurabilityMin, Config.Slabs.DurabilityMax),
				extraWeight = 0, weightUntil = 0, cracks = {}, lastStage = -1 }
			for j = 1, 3 do
				local crack = U.part(model, "Fracture", Vector3.new(0.09,0.03,5),
					cf*CFrame.new((j-2)*1.5,1.03,0)*CFrame.Angles(0,(j-2)*0.7,0), Color3.fromRGB(36,25,18), Enum.Material.SmoothPlastic)
				crack.Transparency = 1; crack.CanCollide = false; crack.CanQuery = false; crack.Massless = true
				U.weld(slab, crack); table.insert(record.cracks, crack)
			end
			table.insert(self.slabs, record)
			slab:SetAttribute("Breakable", true)
		end
	end
	self.ray = RaycastParams.new(); self.ray.FilterType = Enum.RaycastFilterType.Include
	self.ray.FilterDescendantsInstances = {model}
	self:BuildScenery(map)
end

function Arena:BuildScenery(map)
	local center = Config.Arena.Center
	if map.Id == "Amazon" then
		local river = U.part(self.model, "River", Vector3.new(130,1,130), CFrame.new(0,22,0), Color3.fromRGB(24,87,78), Enum.Material.Glass)
		river.Transparency = 0.25; river.CanCollide = false; river.CanQuery = false
		for i = 1, 20 do
			local a = i*math.pi/10
			local base = center+Vector3.new(math.cos(a)*101,-9,math.sin(a)*101)
			U.part(self.model, "JungleTrunk", Vector3.new(5,45,5), CFrame.new(base), Color3.fromRGB(69,48,30), Enum.Material.Wood)
			local canopy = U.part(self.model, "Canopy", Vector3.new(26,20,26), CFrame.new(base+Vector3.new(0,25,0)), Color3.fromRGB(34,87,52), Enum.Material.Grass)
			canopy.Shape = Enum.PartType.Ball
		end
	else
		for i = 1, 24 do
			local a = i*math.pi/12
			local cf = CFrame.new(center+Vector3.new(math.sin(a)*100,17,math.cos(a)*100))*CFrame.Angles(0,a,0)
			U.part(self.model, "AmphitheaterWall", Vector3.new(26,44,5), cf, Color3.fromRGB(141,127,107), Enum.Material.Sandstone)
			U.part(self.model, "Banner", Vector3.new(6,16,0.2), cf*CFrame.new(0,4,-3), Color3.fromRGB(119,36,41), Enum.Material.Fabric)
		end
	end
end

function Arena:Start()
	self.core.Anchored = false
	self.core:SetNetworkOwner(nil)
end

function Arena:Stop()
	if self.core and self.core.Parent then self.core.Anchored = true end
end

function Arena:Under(root)
	if not self.ray then return nil end
	local hit = workspace:Raycast(root.Position, Vector3.new(0,-8,0), self.ray)
	if not hit then return nil end
	for _, s in self.slabs do
		if not s.broken and s.part == hit.Instance then return s end
	end
	return nil
end

function Arena:Break(s)
	if s.broken then return end
	s.broken = true; s.part:SetAttribute("Broken", true)
	if s.pickup then s.pickup:Destroy(); s.pickup = nil end
	s.weld:Destroy()
	s.part:SetNetworkOwner(nil)
	s.part:ApplyImpulse(Vector3.new(self.rng:NextNumber(-3,3),-9,self.rng:NextNumber(-3,3))*s.part.AssemblyMass)
	s.part.AssemblyAngularVelocity = Vector3.new(self.rng:NextNumber(-2,2),0,self.rng:NextNumber(-2,2))
	for _, crack in s.cracks do Debris:AddItem(crack,5) end
	Debris:AddItem(s.part,5)
	self.fx:FireAllClients("Break", s.part.Position)
	for _, neighbor in self.slabs do
		if not neighbor.broken and (neighbor.part.Position-s.part.Position).Magnitude < 12 then neighbor.stress += 2.5 end
	end
end

function Arena:Step(dt, active)
	self.age += dt
	local tx, tz = 0,0
	local weights = {}
	for _, p in active do
		local root = U.root(p)
		if root then
			local s = self:Under(root)
			if s then
				local weight = if (p:GetAttribute("AnchorUntil") or 0) > workspace:GetServerTimeNow() then 3 else 1
				weights[s] = (weights[s] or 0) + weight
				local offset = root.Position - Config.Arena.Center
				tx += offset.X*weight; tz += offset.Z*weight
			end
		end
	end
	for _, s in self.slabs do
		if s.broken then continue end
		if os.clock() < s.weightUntil then
			local offset = s.part.Position-Config.Arena.Center
			tx += offset.X*s.extraWeight; tz += offset.Z*s.extraWeight
			weights[s] = (weights[s] or 0)+s.extraWeight
		end
	end
	local wave = self.map.Wave
	local pitch, roll = Rules.limitTilt(tz*Config.Arena.TiltPerStud+math.sin(self.age*1.6)*wave,
		-tx*Config.Arena.TiltPerStud+math.sin(self.age*1.1+1)*wave, Config.Arena.MaxTilt)
	self.orientation.CFrame = CFrame.Angles(math.rad(pitch),0,math.rad(roll))
	local tilt = math.sqrt(pitch*pitch+roll*roll)/Config.Arena.MaxTilt
	for _, s in self.slabs do
		if s.broken then continue end
		if self.age > Config.Slabs.Grace then
			s.stress += Rules.stressRate(weights[s] or 0, tilt, self.age, self.map.Duration)*dt
		end
		local fraction = s.stress/s.durability
		local stage = if fraction >= 0.85 then 3 elseif fraction >= 0.55 then 2 elseif fraction >= 0.3 then 1 else 0
		if stage ~= s.lastStage then
			s.lastStage = stage
			s.part.Color = self.map.Color:Lerp(Color3.fromRGB(99,51,37),math.clamp(fraction,0,1)*0.65)
			for j, crack in s.cracks do crack.Transparency = if j <= stage then 0 else 1 end
		end
		if fraction >= 0.85 and not s.warningAt then s.warningAt = self.age end
		if fraction < 0.85 then s.warningAt = nil end
		if fraction >= 1 and s.warningAt and self.age-s.warningAt >= Config.Slabs.WarningTime then self:Break(s) end
	end
end

function Arena:SpawnPoints(count)
	-- Spread spawns around the perimeter, snapped onto distinct intact slabs.
	local candidates = table.clone(self.slabs)
	table.sort(candidates,function(a,b)
		local a0 = a.part.Position-Config.Arena.Center; local b0 = b.part.Position-Config.Arena.Center
		return math.atan2(a0.Z,a0.X) < math.atan2(b0.Z,b0.X)
	end)
	local result = {}
	for i = 1,count do
		local index = math.floor((i-1)*#candidates/count)+1
		local pos = candidates[index].part.Position+Vector3.new(0,5,0)
		local target = Vector3.new(0,pos.Y,0)
		if (pos-target).Magnitude < 0.1 then target = pos+Vector3.new(0,0,-1) end
		result[i] = CFrame.lookAt(pos,target)
	end
	return result
end

function Arena:LobbyCFrame(index)
	return self.spawn*CFrame.new(((index or 1)-1)%5*3-6,0,0)
end
return Arena
