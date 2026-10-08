--!nonstrict
local Debris=game:GetService("Debris")
local Config=require(game:GetService("ReplicatedStorage").Shared.Config)
local U=require(script.Parent.Util)
local LionRig=require(script.Parent.LionRig)

local Hazards={}; Hazards.__index=Hazards

function Hazards.new(round,arena,combat,fx)
	local folder=Instance.new("Folder"); folder.Name="ArenaHazards"; folder.Parent=arena.world
	return setmetatable({
		round=round,arena=arena,combat=combat,fx=fx,folder=folder,
		current=nil,nextAt=math.huge,lastType=nil,lions={},warnings={},nextLionThink=0,rng=Random.new(),
	},Hazards)
end

function Hazards:Reset()
	self.current=nil
	table.clear(self.warnings)
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
	if self.current then return end
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
	-- The dedicated hazard strip carries this message without a second popup.
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

function Hazards:ImpactMeteor(position,slab)
	if self.round.phase~="Live" then return end
	if slab and not slab.broken then
		-- A direct meteor hit is catastrophic: the exact struck tile fractures away immediately.
		self.arena:Break(slab)
	end
	self.arena:ImpactTilt(position,Config.Hazards.MeteorImpactTilt)
	for _,actor in self.round:Active() do
		local root=U.root(actor)
		if root then
			local delta=root.Position-position
			local flat=Vector3.new(delta.X,0,delta.Z)
			local d=flat.Magnitude
			if d<12 and math.abs(delta.Y)<10 then
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
	local target=slab.part.Position+Vector3.new(self.rng:NextNumber(-2.2,2.2),3,self.rng:NextNumber(-2.2,2.2))
	local event=self.current
	local totalTime=Config.Hazards.MeteorTelegraphTime+Config.Hazards.MeteorFallTime
	local warning={position=target,radius=12,untilTime=os.clock()+totalTime}
	table.insert(self.warnings,warning)
	self.fx:FireAllClients("DangerCircle",target,12)

	-- Telegraph first, then let the meteor itself cross the sky extremely fast.
	task.delay(Config.Hazards.MeteorTelegraphTime,function()
		if self.current~=event or not event or self.round.phase~="Live" or slab.broken then return end
		self.fx:FireAllClients(
			"MeteorIncoming",
			target+Vector3.new(0,Config.Hazards.MeteorFallHeight,0),
			target
		)
	end)
	task.delay(totalTime,function()
		local index=table.find(self.warnings,warning); if index then table.remove(self.warnings,index) end
		if self.current==event and event and self.round.phase=="Live" and not slab.broken then
			self:ImpactMeteor(target,slab)
		end
	end)
end

function Hazards:CreateLion(index)
	local desired=Config.Arena.Center+Vector3.new(math.cos(index*2.3)*72,0,math.sin(index*2.3)*72)
	local best,distance=nil,math.huge
	for _,slab in self.arena.slabs do
		local d=(slab.part.Position-desired).Magnitude
		if not slab.broken and slab.stress<slab.durability*.7 and d<distance then best=slab; distance=d end
	end
	if not best then return end
	local position=best.part.Position+Vector3.new(0,7,0)
	local rig=LionRig.create(self.folder,CFrame.lookAt(position,Vector3.new(0,position.Y,0)),index)
	table.insert(self.lions,{model=rig,nextHit=os.clock()+1})
	self.fx:FireAllClients("LionSpawn",position)
end

function Hazards:ThreatAt(position)
	local escape=Vector3.zero
	for _,warning in self.warnings do
		local delta=position-warning.position
		local flat=Vector3.new(delta.X,0,delta.Z)
		if flat.Magnitude<warning.radius+7 and flat.Magnitude>.05 then escape+=flat.Unit*(warning.radius+7-flat.Magnitude) end
	end
	for _,lion in self.lions do
		local root=U.root(lion.model)
		if root then
			local delta=position-root.Position; local flat=Vector3.new(delta.X,0,delta.Z)
			if flat.Magnitude<16 and flat.Magnitude>.05 then escape+=flat.Unit*(16-flat.Magnitude) end
		end
	end
	return escape
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
		self.arena:AddHazardWeight(root.Position,.72,.4)
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
			local heading=nil; local score=-math.huge
			for j=0,11 do
				local a=j/12*math.pi*2; local dir=Vector3.new(math.sin(a),0,math.cos(a))
				local near=self.arena:GroundAt(root.Position+dir*4+Vector3.new(0,5,0),20)
				local far=self.arena:GroundAt(root.Position+dir*9+Vector3.new(0,7,0),26)
				if near and far then
					local value=dir:Dot(flat.Unit)-far.stress/far.durability*.5
					if value>score then score=value; heading=dir end
				end
			end
			hum:Move(heading or Vector3.zero,false)

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
	elseif h.kind=="Lions" and now>=self.nextLionThink then
		self.nextLionThink=now+.12
		self:StepLions()
	end
	if now>=h.endAt then self:Finish() end
end

return Hazards
