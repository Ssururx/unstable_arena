--!nonstrict
local Config=require(game:GetService("ReplicatedStorage").Shared.Config)
local U=require(script.Parent.Util)

local Stamina=require(script.Parent.Stamina)
local Movement={}; Movement.__index=Movement

function Movement.new(round,arena,combat,fx)
	return setmetatable({round=round,arena=arena,combat=combat,fx=fx,times={},bursts={}},Movement)
end

function Movement:Ready(p,key,cooldown)
	local t=self.times[p] or {}; self.times[p]=t
	local now=os.clock()
	if now-(t[key] or -100)<cooldown then return false end
	t[key]=now; return true
end

function Movement:Clear(p)
	self.times[p]=nil
	Stamina.reset(p)
	self:EndBurst(p)
	p:SetAttribute("Sprinting",false)
	p:SetAttribute("SlidingUntil",0)
	p:SetAttribute("DashUntil",0)
	p:SetAttribute("Adrenaline",0)
	p:SetAttribute("AdrenalineUntil",0)
	local _,hum=U.root(p)
	if hum then hum.WalkSpeed=Config.Movement.WalkSpeed end
end

function Movement:EndBurst(p)
	local burst=self.bursts[p]; self.bursts[p]=nil
	if not burst then return end
	local root,hum=U.root(p)
	if root and not root.Anchored and not hum.PlatformStand and root:CanSetNetworkOwnership() then
		if p:IsA("Player") then root:SetNetworkOwnershipAuto() else root:SetNetworkOwner(nil) end
	end
end
function Movement:Burst(p,direction,speed,duration,sliding)
	self:EndBurst(p)
	local root=U.root(p)
	if root:CanSetNetworkOwnership() then root:SetNetworkOwner(nil) end
	self.bursts[p]={direction=direction,speed=speed,duration=duration,age=0,sliding=sliding}
end
function Movement:Step(dt)
	for _,actor in self.round:Active() do
		local _,hum=U.root(actor)
		Stamina.step(actor,dt,hum and hum.MoveDirection.Magnitude>.05 and not hum.PlatformStand)
	end
	for p,burst in self.bursts do
		local root,hum=U.root(p)
		burst.age+=dt
		if not self.round:IsActive(p) or not root or root.Anchored or hum.PlatformStand or burst.age>=burst.duration then
			self:EndBurst(p); continue
		end
		local speed=burst.speed*(if burst.sliding then 1-.48*burst.age/burst.duration else 1)
		local v=root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity=Vector3.new(burst.direction.X*speed,v.Y,burst.direction.Z*speed)
	end
end

function Movement:Sprint(p,on)
	if not self.round:IsActive(p) then p:SetAttribute("Sprinting",false); return end
	on=on==true and (p:GetAttribute("Stamina") or Config.Stamina.Max)>5
	p:SetAttribute("Sprinting",on)
	local _,hum=U.root(p); if not hum then return end
	local now=workspace:GetServerTimeNow()
	hum.WalkSpeed=if now<(p:GetAttribute("AdrenalineUntil") or 0)
		then Config.Movement.AdrenalineSpeed
		elseif on then Config.Movement.SprintSpeed else Config.Movement.WalkSpeed
end

function Movement:Dash(p,aim)
	if not self.round:IsActive(p) or not self:Ready(p,"Dash",Config.Movement.DashCooldown) then return end
	local root,hum=U.root(p); if not root or hum.PlatformStand then return end
	local direction=self.combat:Aim(p,aim)
	local flat=Vector3.new(direction.X,0,direction.Z)
	if flat.Magnitude<.1 then flat=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z) end
	if flat.Magnitude<.1 then return end
	flat=flat.Unit
	if not Stamina.spend(p,Config.Stamina.DashCost) then return end
	self:Burst(p,flat,Config.Movement.DashSpeed,.18,false)
	local v=root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity=Vector3.new(flat.X*Config.Movement.DashSpeed,math.max(v.Y,2),flat.Z*Config.Movement.DashSpeed)
	p:SetAttribute("DashUntil",workspace:GetServerTimeNow()+.28)
	U.notify(self.fx,p,"Cooldown","Dash",Config.Movement.DashCooldown)
	self.fx:FireAllClients("Dash",root.Position,flat)
end

function Movement:Slide(p,aim)
	if not self.round:IsActive(p) or not self:Ready(p,"Slide",Config.Movement.SlideCooldown) then return end
	local root,hum=U.root(p); if not root or hum.PlatformStand then return end
	if hum.FloorMaterial==Enum.Material.Air or not self.arena:Under(root) then return end
	local direction=self.combat:Aim(p,aim)
	local flat=Vector3.new(direction.X,0,direction.Z)
	if flat.Magnitude<.1 then flat=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z) end
	if flat.Magnitude<.1 then return end
	flat=flat.Unit
	local normal=self.arena.core and self.arena.core.CFrame.UpVector or Vector3.yAxis
	local downhill=Vector3.new(0,-1,0)-normal*Vector3.new(0,-1,0):Dot(normal)
	if downhill.Magnitude>.05 then flat=(flat+downhill.Unit*.42).Unit end
	local momentum=Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z).Magnitude
	if not Stamina.spend(p,Config.Stamina.SlideCost) then return end
	self:Burst(p,flat,math.clamp(momentum+8,Config.Movement.SlideSpeed,55),.52,true)
	local v=root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity=Vector3.new(flat.X*Config.Movement.SlideSpeed,math.min(v.Y,0),flat.Z*Config.Movement.SlideSpeed)
	p:SetAttribute("SlidingUntil",workspace:GetServerTimeNow()+.72)
	U.notify(self.fx,p,"Cooldown","Slide",Config.Movement.SlideCooldown)
	self.fx:FireAllClients("Slide",root.Position,flat)
end

function Movement:Adrenaline(p)
	if not self.round:IsActive(p) then return end
	local current=p:GetAttribute("Adrenaline") or 0
	if current<Config.Adrenaline.Max then
		U.notify(self.fx,p,"Toast","ADRENALINE "..math.floor(current).."%")
		return
	end
	p:SetAttribute("Adrenaline",0)
	p:SetAttribute("AdrenalineUntil",workspace:GetServerTimeNow()+Config.Adrenaline.Duration)
	local root,hum=U.root(p)
	if hum then hum.WalkSpeed=Config.Movement.AdrenalineSpeed end
	if root then self.fx:FireAllClients("Adrenaline",root.Position) end
	U.notify(self.fx,p,"Toast","ADRENALINE RUSH")
end

return Movement
