--!nonstrict
local Debris=game:GetService("Debris")
local Config=require(game:GetService("ReplicatedStorage").Shared.Config)
local U=require(script.Parent.Util)

local Hazards={}; Hazards.__index=Hazards

function Hazards.new(round,arena,combat,fx)
	local folder=Instance.new("Folder"); folder.Name="ArenaHazards"; folder.Parent=arena.world
	return setmetatable({
		round=round,arena=arena,combat=combat,fx=fx,folder=folder,
		current=nil,nextAt=math.huge,lastType=nil,lions={},rng=Random.new(),
	},Hazards)
end

function Hazards:Reset()
	self.current=nil
	self.nextAt=os.clock()+Config.Hazards.FirstDelay
	self.lastType=nil
	for _,lion in self.lions do
		if lion.model and lion.model.Parent then lion.model:Destroy() end
	end
	table.clear(self.lions)
	for _,child in self.folder:GetChildren() do child:Destroy() end
	workspace:SetAttribute("Hazard","")
	workspace:SetAttribute("HazardEndsAt",0)
	workspace:SetAttribute("HazardActiveAt",0)
end

function Hazards:Choose()
	local kind=if self.rng:NextNumber()<.5 then "Meteor" else "Lions"
	if kind==self.lastType then kind=if kind=="Meteor" then "Lions" else "Meteor" end
	return kind
end

function Hazards:Begin(kind)
	local now=os.clock()
	local duration=if kind=="Meteor" then Config.Hazards.MeteorDuration else Config.Hazards.LionDuration
	self.current={
		kind=kind,
		activeAt=now+Config.Hazards.Warning,
		endAt=now+Config.Hazards.Warning+duration,
		nextPulse=now+Config.Hazards.Warning,
		started=false,
	}
	self.lastType=kind
	workspace:SetAttribute("Hazard",kind)
	workspace:SetAttribute("HazardActiveAt",workspace:GetServerTimeNow()+Config.Hazards.Warning)
	workspace:SetAttribute("HazardEndsAt",workspace:GetServerTimeNow()+Config.Hazards.Warning+duration)
	local message=if kind=="Meteor"
		then "⚠ METEOR SHOWER IN "..Config.Hazards.Warning.."s · WATCH THE GROUND"
		else "⚠ LION GATES OPEN IN "..Config.Hazards.Warning.."s · KEEP MOVING"
	self.fx:FireAllClients("Toast",message)
	self.fx:FireAllClients("HazardWarning",Config.Arena.Center,kind)
end

function Hazards:Finish()
	if not self.current then return end
	for _,lion in self.lions do
		if lion.model and lion.model.Parent then lion.model:Destroy() end
	end
	table.clear(self.lions)
	self.current=nil
	workspace:SetAttribute("Hazard","")
	workspace:SetAttribute("HazardEndsAt",0)
	workspace:SetAttribute("HazardActiveAt",0)
	self.nextAt=os.clock()+self.rng:NextNumber(Config.Hazards.MinGap,Config.Hazards.MaxGap)
end

function Hazards:ImpactMeteor(position)
	if self.round.phase~="Live" then return end
	local slab=self.arena:AddHazardWeight(position,1.9,6)
	if slab and not slab.broken then
		slab.stress+=7
		local stone=U.part(slab.model,"MeteorFragment",Vector3.new(3.2,2.3,3.2),slab.part.CFrame*CFrame.new(0,3.3,0),Color3.fromRGB(72,61,52),Enum.Material.Rock)
		stone.Shape=Enum.PartType.Ball; stone.Massless=true; stone.CanCollide=false; stone.CanQuery=false
		U.weld(slab.part,stone); Debris:AddItem(stone,6)
	end
	for _,actor in self.round:Active() do
		local root=U.root(actor)
		if root then
			local delta=root.Position-position
			local flat=Vector3.new(delta.X,0,delta.Z)
			local d=flat.Magnitude
			if d<12 then
				local direction=if d>.1 then flat.Unit else Vector3.xAxis
				self.combat:Knock(actor,direction*(56*(1-d/15))+Vector3.new(0,12,0),nil)
			end
		end
	end
	self.fx:FireAllClients("MeteorImpact",position,10)
end

function Hazards:SpawnMeteor()
	local candidates={}
	for _,slab in self.arena.slabs do
		if not slab.broken then table.insert(candidates,slab) end
	end
	if #candidates==0 then return end
	local slab=candidates[self.rng:NextInteger(1,#candidates)]
	local target=slab.part.Position+Vector3.new(self.rng:NextNumber(-3,3),3,self.rng:NextNumber(-3,3))
	self.fx:FireAllClients("DangerCircle",target,8)
	self.fx:FireAllClients("MeteorIncoming",target+Vector3.new(0,85,0),target)
	task.delay(1.15,function()
		if self.current and self.current.kind=="Meteor" and self.round.phase=="Live" then
			self:ImpactMeteor(target)
		end
	end)
end

local function lionPart(parent,name,size,cf,color)
	local p=U.part(parent,name,size,cf,color,Enum.Material.SmoothPlastic)
	p.Anchored=false; p.CanCollide=false; p.CanQuery=false; p.CanTouch=false
	return p
end

function Hazards:CreateLion(index)
	local rig=Instance.new("Model"); rig.Name="ArenaLion_"..index; rig.Parent=self.folder
	rig:SetAttribute("DisplayName","Arena Lion")
	local angle=(index-1)*math.pi+.55
	local pos=Config.Arena.Center+Vector3.new(math.cos(angle)*82,7,math.sin(angle)*82)
	local root=lionPart(rig,"HumanoidRootPart",Vector3.new(3,2,5),CFrame.new(pos),Color3.new())
	root.Transparency=1; root.RootPriority=100
	local body=lionPart(rig,"Body",Vector3.new(4.4,2.6,6),root.CFrame,Color3.fromRGB(183,132,67)); body.CanCollide=true
	local head=lionPart(rig,"Head",Vector3.new(3.2,3,3),root.CFrame*CFrame.new(0,.7,-3.6),Color3.fromRGB(190,139,72))
	local mane=lionPart(rig,"Mane",Vector3.new(4,3.8,2.2),root.CFrame*CFrame.new(0,.7,-2.8),Color3.fromRGB(92,62,39))
	local tail=lionPart(rig,"Tail",Vector3.new(.35,.35,3.8),root.CFrame*CFrame.new(0,.5,4.4)*CFrame.Angles(-.35,0,0),Color3.fromRGB(145,96,52))
	U.weld(root,body); U.weld(root,head); U.weld(root,mane); U.weld(root,tail)
	for _,x in {-1.4,1.4} do
		for _,z in {-1.8,1.8} do
			local leg=lionPart(rig,"Leg",Vector3.new(.7,2.2,.7),root.CFrame*CFrame.new(x,-1.8,z),Color3.fromRGB(167,115,58))
			U.weld(root,leg)
		end
	end
	local hum=Instance.new("Humanoid"); hum.RequiresNeck=false; hum.BreakJointsOnDeath=false
	hum.WalkSpeed=21; hum.JumpPower=42; hum.HipHeight=.4; hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
	hum.Parent=rig; rig.PrimaryPart=root; root:SetNetworkOwner(nil)
	table.insert(self.lions,{model=rig,nextHit=0})
	self.fx:FireAllClients("LionSpawn",root.Position)
end

function Hazards:StartLions()
	local count=if #self.round:Active()>=7 then 2 else 1
	for i=1,count do self:CreateLion(i) end
end

function Hazards:StepLions()
	local active=self.round:Active()
	for i=#self.lions,1,-1 do
		local lion=self.lions[i]
		local root,hum=U.root(lion.model)
		if not root or root.Position.Y<Config.Arena.VoidY then
			if lion.model.Parent then lion.model:Destroy() end
			table.remove(self.lions,i); continue
		end
		self.arena:AddHazardWeight(root.Position,2.15,.4)
		local target,distance=nil,math.huge
		for _,actor in active do
			local other=U.root(actor)
			if other then
				local d=(other.Position-root.Position).Magnitude
				if d<distance then target=actor; distance=d end
			end
		end
		if not target then hum:Move(Vector3.zero,false); continue end
		local other=U.root(target)
		local flat=Vector3.new(other.Position.X-root.Position.X,0,other.Position.Z-root.Position.Z)
		if flat.Magnitude>.1 then
			local dir=flat.Unit
			local ahead=self.arena:GroundAt(root.Position+dir*7+Vector3.new(0,8,0),26)
			if ahead then
				hum:Move(dir,false)
				local v=root.AssemblyLinearVelocity
				root.AssemblyLinearVelocity=Vector3.new(dir.X*21,v.Y,dir.Z*21)
			else
				local inward=Vector3.new(Config.Arena.Center.X-root.Position.X,0,Config.Arena.Center.Z-root.Position.Z)
				local safe=if inward.Magnitude>.1 then inward.Unit else Vector3.zero
				hum:Move(safe,false)
				local v=root.AssemblyLinearVelocity
				root.AssemblyLinearVelocity=Vector3.new(safe.X*18,v.Y,safe.Z*18)
			end
		end
		if distance<5.2 and os.clock()>lion.nextHit then
			lion.nextHit=os.clock()+2
			local dir=if flat.Magnitude>.1 then flat.Unit else root.CFrame.LookVector
			self.combat:Knock(target,dir*52+Vector3.new(0,10,0),nil)
			self.fx:FireAllClients("LionAttack",other.Position)
		end
	end
end

function Hazards:Step()
	if self.round.phase~="Live" then return end
	local now=os.clock()
	if not self.current then
		local timeLeft=(workspace:GetAttribute("EndsAt") or 0)-workspace:GetServerTimeNow()
		if now>=self.nextAt and timeLeft>28 then self:Begin(self:Choose()) end
		return
	end
	local h=self.current
	if now<h.activeAt then return end
	if not h.started then
		h.started=true
		if h.kind=="Lions" then self:StartLions() end
	end
	if h.kind=="Meteor" and now>=h.nextPulse then
		h.nextPulse=now+self.rng:NextNumber(1.25,1.8)
		self:SpawnMeteor()
	elseif h.kind=="Lions" then
		self:StepLions()
	end
	if now>=h.endAt then self:Finish() end
end

return Hazards
