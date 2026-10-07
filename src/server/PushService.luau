--!nonstrict
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Rules = require(game:GetService("ReplicatedStorage").Shared.Rules)
local U = require(script.Parent.Util)
local Combat = {}
Combat.__index = Combat

function Combat.new(round, arena, fx)
	return setmetatable({round = round, arena = arena, fx = fx, times = {}, ownership = {}, credit = {}}, Combat)
end
function Combat:Ready(p, kind, cooldown)
	local t = self.times[p] or {}; self.times[p] = t
	local now = os.clock()
	if now-(t[kind] or -100) < cooldown then return false end
	t[kind] = now
	return true
end
function Combat:Forget(p)
	self.times[p] = nil; self.credit[p] = nil
end
function Combat:AddAdrenaline(actor,amount)
	if not actor or not self.round:IsActive(actor) then return end
	local current=actor:GetAttribute("Adrenaline") or 0
	actor:SetAttribute("Adrenaline",math.clamp(current+amount,0,Config.Adrenaline.Max))
end
function Combat:CanAct(p)
	return self.round:IsActive(p) or (p:IsA("Player") and p:GetAttribute("InRound") ~= true and U.root(p) ~= nil)
end
function Combat:Enemy(a,b)
	if b:GetAttribute("Practice") then return a:IsA("Player") end
	return self.round:IsActive(a) and self.round:IsActive(b)
		and a:GetAttribute("TeamId") ~= b:GetAttribute("TeamId")
end
function Combat:Visible(a,b)
	local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {a.Parent,b.Parent}
	return workspace:Raycast(a.Position,b.Position-a.Position,params) == nil
end
function Combat:Target(p, range, allowAlly)
	local root = U.root(p); if not root then return nil end
	local targets = self.round:Active()
	for _, d in self.arena.dummies do table.insert(targets,d.model) end
	local best, bestDistance = nil, math.huge
	for _, target in targets do
		if target == p then continue end
		local ally = self.round:IsActive(p) and self.round:IsActive(target)
			and p:GetAttribute("TeamId") == target:GetAttribute("TeamId")
		if not self:Enemy(p,target) and not (allowAlly and ally) then continue end
		local other = U.root(target)
		if other then
			local delta = other.Position-root.Position
			local flat = Vector3.new(delta.X,0,delta.Z)
			local forward = Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z)
			local facing = flat.Magnitude < 0.05 or (forward.Magnitude > 0.05 and forward.Unit:Dot(flat.Unit) > 0.15)
			if delta.Magnitude <= range and facing and delta.Magnitude < bestDistance and self:Visible(root,other) then
				best = target; bestDistance = delta.Magnitude
			end
		end
	end
	return best
end
function Combat:Knock(target, velocity, attacker, isRescue)
	local root, hum = U.root(target); if not root or root.Anchored then return false end
	local now = workspace:GetServerTimeNow()
	if not isRescue then
		if (target:GetAttribute("ShieldUntil") or 0) > now then
			target:SetAttribute("ShieldUntil",0)
			local shield = root.Parent:FindFirstChild("ArenaShield"); if shield then shield:Destroy() end
			self.fx:FireAllClients("Block",root.Position); return false
		end
		if (target:GetAttribute("AnchorUntil") or 0) > now then velocity *= 0.28 end
		if (target:GetAttribute("AdrenalineUntil") or 0) > now then velocity *= Config.Adrenaline.KnockResistance end
	end
	-- Temporarily own the victim assembly so local character simulation cannot swallow the impulse.
	local canSet = root:CanSetNetworkOwnership()
	if canSet then root:SetNetworkOwner(nil) end
	local token = (self.ownership[root] or 0)+1; self.ownership[root] = token
	hum.PlatformStand = true
	local v = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = Vector3.new(v.X*0.15,math.max(v.Y,0)*0.2,v.Z*0.15)+velocity
	if attacker and not isRescue and self.round.alive[target] then
		self.credit[target] = { player = attacker, time = os.clock() }
		self:AddAdrenaline(attacker,Config.Adrenaline.LandHitGain)
		self:AddAdrenaline(target,Config.Adrenaline.HitGain)
	end
	task.delay(Config.Combat.Recovery,function()
		if self.ownership[root] ~= token then return end
		self.ownership[root] = nil
		if root.Parent and hum.Parent then
			hum.PlatformStand = false
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
			local canReset = root:CanSetNetworkOwnership()
			if canReset then
				if target:IsA("Player") then root:SetNetworkOwnershipAuto() else root:SetNetworkOwner(nil) end
			end
		end
	end)
	self.fx:FireAllClients("Hit",root.Position,velocity)
	return true
end
function Combat:Push(p, power, ram)
	if not self:CanAct(p) or not self:Ready(p,"Push",Config.Combat.Cooldown) then return false end
	local root = U.root(p); if not root then return false end
	p:SetAttribute("SwingUntil",workspace:GetServerTimeNow()+.24)
	U.notify(self.fx,p,"Cooldown","Push",Config.Combat.Cooldown)
	self.fx:FireAllClients("Swing",root.Position,root.CFrame.LookVector)
	local target = self:Target(p, if ram then 11 else Config.Combat.Range, false)
	if not target then return true end
	local other = U.root(target)
	local delta = other.Position-root.Position
	local flat = Vector3.new(delta.X,0,delta.Z)
	local direction = if flat.Magnitude > 0.01 then flat.Unit else root.CFrame.LookVector
	local strength=power or Config.Combat.Power
	if (p:GetAttribute("AdrenalineUntil") or 0)>workspace:GetServerTimeNow() then strength*=1.14 end
	self:Knock(target,direction*strength+Vector3.new(0,Config.Combat.Lift,0),p)
	if ram then
		self:Knock(p,-direction*24+Vector3.new(0,6,0),nil,true)
	else
		root:ApplyImpulse(-direction*4*root.AssemblyMass)
	end
	return true
end
function Combat:Grab(p)
	if not self:CanAct(p) or not self:Ready(p,"Grab",Config.Combat.GrabCooldown) then return end
	p:SetAttribute("GrabUntil",workspace:GetServerTimeNow()+.38)
	U.notify(self.fx,p,"Cooldown","Grab",Config.Combat.GrabCooldown)
	local target = self:Target(p,Config.Combat.GrabRange,true)
	if not target then return end
	local root = U.root(p); local other = U.root(target)
	local delta = root.Position-other.Position; local flat = Vector3.new(delta.X,0,delta.Z)
	if flat.Magnitude < 0.1 then return end
	local rescue = self.round:IsActive(target) and p:GetAttribute("TeamId") == target:GetAttribute("TeamId")
	self:Knock(target,flat.Unit*32+Vector3.new(0,12,0),p,rescue)
	root:ApplyImpulse(-flat.Unit*8*root.AssemblyMass)
	self.fx:FireAllClients("Grab",root.Position,other.Position)
end
function Combat:Aim(p, aim)
	local root = U.root(p); if not root then return nil end
	if typeof(aim) ~= "Vector3" or not Rules.validNumber(aim.X) or not Rules.validNumber(aim.Y)
		or not Rules.validNumber(aim.Z) or aim.Magnitude < 0.5 or aim.Magnitude > 1.5 then
		return root.CFrame.LookVector
	end
	return aim.Unit
end
return Combat
