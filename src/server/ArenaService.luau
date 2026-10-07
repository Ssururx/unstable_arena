--!nonstrict
local Debris=game:GetService("Debris")
local Shared=game:GetService("ReplicatedStorage").Shared
local Config=require(Shared.Config)
local Rules=require(Shared.Rules)
local Stone=require(Shared.StoneLayout)
local U=require(script.Parent.Util)
local G=require(script.Parent.Geometry)
local Coliseum=require(script.Parent.Coliseum)
local Arena={}; Arena.__index=Arena
function Arena.new(fx)
	local self=setmetatable({fx=fx,slabs={},byPart={},age=0,rng=Random.new(),dummies={}},Arena)
	local world=Instance.new("Model"); world.Name="UnstableArenaWorld"; world.Parent=workspace; self.world=world
	local lobby=Coliseum.build(world); self.spawn=lobby.spawn; self.pads=lobby.pads
	self:MakeDummy(CFrame.new(30,70,-81)); return self
end
function Arena:MakeDummy(home)
	local rig=Instance.new("Model"); rig.Name="PracticeDummy"; rig.Parent=self.world
	local root=U.part(rig,"HumanoidRootPart",Vector3.new(2,2,1),home); root.Transparency=1; root.CanCollide=false
	local torso=U.part(rig,"Torso",Vector3.new(2.5,2.5,1.5),home,Color3.fromRGB(111,83,52),Enum.Material.Wood); U.weld(root,torso)
	local head=U.part(rig,"Head",Vector3.new(1.5,1.5,1.5),home*CFrame.new(0,2,0),Color3.fromRGB(162,125,79),Enum.Material.Wood); U.weld(root,head)
	for _,x in {-.65,.65} do U.weld(root,U.part(rig,"Leg",Vector3.new(1,2,1),home*CFrame.new(x,-2,0),torso.Color,Enum.Material.Wood)) end
	local h=Instance.new("Humanoid"); h.RequiresNeck=false; h.BreakJointsOnDeath=false; h.MaxHealth=100000; h.Health=100000
	h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None; h.Parent=rig
	rig.PrimaryPart=root; root.Anchored=false; root:SetNetworkOwner(nil); rig:SetAttribute("Practice",true)
	local text=U.label(head,"PRACTICE"); text.Parent.MaxDistance=25
	table.insert(self.dummies,{model=rig,home=home})
end
function Arena:StepPractice()
	for _,d in self.dummies do
		local root,hum=U.root(d.model)
		if root then
			if (root.Position-d.home.Position).Magnitude>6 and not d.movedAt then d.movedAt=os.clock() end
			if root.Position.Y<40 or (d.movedAt and os.clock()-d.movedAt>2.5) then
				d.model:PivotTo(d.home); root.AssemblyLinearVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero
				hum.PlatformStand=false; d.movedAt=nil
			end
		end
	end
end
function Arena:SetPadPhase(phase,counts)
	for _,pad in self.pads do
		local enabled=(phase=="MapVote" and pad.kind=="map") or (phase=="ModeVote" and pad.kind=="mode")
		pad.part.Color=if enabled then Color3.fromRGB(143,115,70) else Color3.fromRGB(85,79,68)
		pad.title.TextColor3=if enabled then Color3.fromRGB(246,226,179) else Color3.fromRGB(153,145,128)
		local votes=counts and counts[pad.kind] and counts[pad.kind][pad.index] or 0
		pad.small.Text=if enabled then "STAND HERE  •  "..votes.." SELECTED" elseif phase=="Live" then "NEXT ROUND" else ""
	end
end
function Arena:PadAt(position,kind)
	for _,pad in self.pads do
		if pad.kind==kind then
			local offset=pad.part.CFrame:PointToObjectSpace(position)
			if math.abs(offset.X)<pad.part.Size.X/2 and math.abs(offset.Z)<pad.part.Size.Z/2 and offset.Y>=0 and offset.Y<7 then return pad.index end
		end
	end
	return nil
end
function Arena:Build(map,seed)
	if self.model then self.model:Destroy() end
	table.clear(self.slabs); table.clear(self.byPart); self.age=0; self.map=map
	local model=Instance.new("Model"); model.Name="RoundArena"; model.Parent=self.world; self.model=model
	local core=U.part(model,"Core",Vector3.new(3,2,3),CFrame.new(Config.Arena.Center))
	core.Transparency=1; core.CanCollide=false; core.CanQuery=false; core.RootPriority=127; self.core=core
	local att=Instance.new("Attachment"); att.Parent=core
	local pos=Instance.new("AlignPosition"); pos.Mode=Enum.PositionAlignmentMode.OneAttachment; pos.Attachment0=att
	pos.Position=Config.Arena.Center; pos.MaxForce=1e9; pos.ApplyAtCenterOfMass=true; pos.Responsiveness=70; pos.MaxVelocity=30; pos.Parent=core
	local orientation=Instance.new("AlignOrientation"); orientation.Mode=Enum.OrientationAlignmentMode.OneAttachment; orientation.Attachment0=att
	orientation.MaxTorque=1e9; orientation.MaxAngularVelocity=Config.Arena.AngularSpeed; orientation.Responsiveness=Config.Arena.Response
	orientation.CFrame=CFrame.identity; orientation.Parent=core; self.orientation=orientation
	local layout=Stone.build(Config.Arena.Radius,Config.Arena.SlabCount,seed or 31415)
	for i,cell in layout do
		local slab=Instance.new("Model"); slab.Name="Stone_"..i; slab.Parent=model
		local y=Config.Arena.Center.Y+self.rng:NextNumber(-.1,.1)
		local cf=CFrame.new(cell.center.x,y,cell.center.z)
		local pivot=U.part(slab,"SlabRoot",Vector3.new(3,4.6,3),cf); pivot.Transparency=1
		pivot.CanCollide=false; pivot.CanQuery=false; pivot.Massless=true; slab.PrimaryPart=pivot
		local color=map.Color:Lerp(Color3.fromRGB(190,175,144),self.rng:NextNumber(0,.28))
		local record={part=pivot,model=slab,cell=cell,weld=U.weld(core,pivot),stress=0,broken=false,
			durability=self.rng:NextNumber(Config.Slabs.DurabilityMin,Config.Slabs.DurabilityMax),extraWeight=0,weightUntil=0,
			cracks={},faces={},lastStage=-1,color=color,neighbors={}}
		for _,p in G.polygon(slab,cell.polygon,y,4.6,color,map.Material) do
			p.CustomPhysicalProperties=PhysicalProperties.new(1.2,.32,.03)
			U.weld(pivot,p); self.byPart[p]=record; table.insert(record.faces,p)
		end
		local lower={}
		for _,v in cell.polygon do table.insert(lower,{x=cell.center.x+(v.x-cell.center.x)*.90,z=cell.center.z+(v.z-cell.center.z)*.90}) end
		for _,p in G.polygon(slab,lower,y-3.15,1.9,color:Lerp(Color3.fromRGB(81,70,62),.45),Enum.Material.Rock) do
			p.Massless=true; p.CanCollide=false; p.CanQuery=false; U.weld(pivot,p)
		end
		-- Branching stress fractures, with no repeated parallel grid pattern.
		for branch=1,3 do
			local vertex=cell.polygon[((i+branch*2)%#cell.polygon)+1]
			local from=Vector3.new(cell.center.x,y+2.315,cell.center.z)
			local to=Vector3.new(vertex.x,y+2.315,vertex.z)
			for step=1,3 do
				local target=from:Lerp(to,1/(4-step))
				if step<3 then target+=Vector3.new(self.rng:NextNumber(-.55,.55),0,self.rng:NextNumber(-.55,.55)) end
				local crack=G.line(slab,"StressFracture",from,target,.065,Color3.fromRGB(43,36,29),Enum.Material.SmoothPlastic)
				crack.Transparency=1; crack.Massless=true; crack.CastShadow=false; U.weld(pivot,crack)
				table.insert(record.cracks,{part=crack,stage=branch}); from=target
			end
		end
		slab:SetAttribute("SlabId",i); table.insert(self.slabs,record)
	end
	for _,s in self.slabs do
		for _,other in self.slabs do
			if s~=other and (s.part.Position-other.part.Position).Magnitude<21 then table.insert(s.neighbors,other) end
		end
	end
	self.ray=RaycastParams.new(); self.ray.FilterType=Enum.RaycastFilterType.Include; self.ray.FilterDescendantsInstances={model}
end
function Arena:Start() self.core.Anchored=false; self.core:SetNetworkOwner(nil) end
function Arena:Stop() if self.core and self.core.Parent then self.core.Anchored=true end end
function Arena:GroundAt(position,depth)
	if not self.ray then return nil,nil end
	local hit=workspace:Raycast(position,Vector3.new(0,-(depth or 12),0),self.ray)
	local slab=hit and self.byPart[hit.Instance]
	if slab and not slab.broken then return slab,hit.Position end
	return nil,nil
end
function Arena:Under(root) return self:GroundAt(root.Position,14) end

function Arena:ApplySlopePhysics(active)
	if not self.core or not self.core.Parent then return end

	for _,actor in active do
		local _,hum=U.root(actor)
		if hum and not hum.PlatformStand then
			hum.WalkSpeed=if actor:GetAttribute("Bot") then Config.Bots.WalkSpeed else 20
		end
	end

	local normal=self.core.CFrame.UpVector
	local tilt=math.deg(math.acos(math.clamp(normal:Dot(Vector3.yAxis),-1,1)))
	if tilt < Config.Arena.SlipStart then return end

	local gravity=Vector3.new(0,-workspace.Gravity,0)
	local downhill=gravity-normal*gravity:Dot(normal)
	if downhill.Magnitude < .01 then return end

	local alpha=math.clamp(
		(tilt-Config.Arena.SlipStart)/(Config.Arena.SlipFull-Config.Arena.SlipStart),
		0,1
	)
	local forceScale=Config.Arena.SlipForce*(.25+.75*alpha)

	for _,actor in active do
		local root,hum=U.root(actor)
		if not root or root.Anchored or hum.PlatformStand then continue end
		local slab=self:Under(root)
		if not slab then continue end

		local traction=if (actor:GetAttribute("AnchorUntil") or 0)>workspace:GetServerTimeNow() then .24 else 1
		local accel=downhill*forceScale*traction
		local v=root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity=Vector3.new(
			v.X+accel.X*.08,
			v.Y,
			v.Z+accel.Z*.08
		)

		if alpha>.55 then
			hum.WalkSpeed=math.max(12,(actor:GetAttribute("Bot") and Config.Bots.WalkSpeed or 20)*(1-alpha*.26))
		end
	end
end
function Arena:Break(s)
	if s.broken then return end
	s.broken=true; s.model:SetAttribute("Broken",true)
	if s.pickup then s.pickup:Destroy(); s.pickup=nil end
	s.weld:Destroy(); s.part:SetNetworkOwner(nil)
	s.part:ApplyImpulse(Vector3.new(self.rng:NextNumber(-2,2),-8,self.rng:NextNumber(-2,2))*s.part.AssemblyMass)
	s.part.AssemblyAngularVelocity=Vector3.new(self.rng:NextNumber(-1,1),0,self.rng:NextNumber(-1,1))
	Debris:AddItem(s.model,5); self.fx:FireAllClients("Break",s.part.Position)
	for _,neighbor in s.neighbors do if not neighbor.broken then neighbor.stress+=2.3 end end
end
function Arena:Step(dt,active)
	self.age+=dt; local tx,tz=0,0; local weights={}
	for _,actor in active do
		local root=U.root(actor)
		if root then
			local slab=self:Under(root)
			if slab then
				local weight=if (actor:GetAttribute("AnchorUntil") or 0)>workspace:GetServerTimeNow() then 3 else 1
				weights[slab]=(weights[slab] or 0)+weight
				local offset=root.Position-Config.Arena.Center; tx+=offset.X*weight; tz+=offset.Z*weight
			end
		end
	end
	for _,s in self.slabs do
		if not s.broken and os.clock()<s.weightUntil then
			local offset=s.part.Position-Config.Arena.Center; tx+=offset.X*s.extraWeight; tz+=offset.Z*s.extraWeight
			weights[s]=(weights[s] or 0)+s.extraWeight
		end
	end
	local intensity=math.clamp(self.age/(self.map.Duration*.72),0,1)
	local chaos=1+intensity*.55
	local pitch,roll=Rules.limitTilt(
		tz*Config.Arena.TiltPerStud*chaos+math.sin(self.age*1.4)*self.map.Wave*chaos,
		-tx*Config.Arena.TiltPerStud*chaos+math.sin(self.age*.9+1)*self.map.Wave*chaos,
		Config.Arena.MaxTilt
	)
	self.orientation.CFrame=CFrame.Angles(math.rad(pitch),0,math.rad(roll))
	local tilt=math.sqrt(pitch*pitch+roll*roll)/Config.Arena.MaxTilt
	self:ApplySlopePhysics(active)
	for _,s in self.slabs do
		if s.broken then continue end
		if self.age>Config.Slabs.Grace then s.stress+=Rules.stressRate(weights[s] or 0,tilt,self.age,self.map.Duration)*dt end
		local fraction=s.stress/s.durability
		local stage=if fraction>=.85 then 3 elseif fraction>=.55 then 2 elseif fraction>=.3 then 1 else 0
		if stage~=s.lastStage then
			s.lastStage=stage
			for _,face in s.faces do face.Color=s.color:Lerp(Color3.fromRGB(101,81,61),stage*.07) end
			for _,crack in s.cracks do crack.part.Transparency=if crack.stage<=stage then 0 else 1 end
			s.model:SetAttribute("DamageStage",stage)
		end
		if fraction>=.85 and not s.warningAt then s.warningAt=self.age; self.fx:FireAllClients("Crack",s.part.Position) end
		if fraction<.85 then s.warningAt=nil end
		if fraction>=1 and s.warningAt and self.age-s.warningAt>=Config.Slabs.WarningTime then self:Break(s) end
	end
end
function Arena:SpawnPoints(count)
	local used={}; local points={}
	for i=1,count do
		local a=(i-1)/count*math.pi*2
		local desired=Config.Arena.Center+Vector3.new(math.sin(a)*76,0,math.cos(a)*76)
		local best,distance=nil,math.huge
		for _,slab in self.slabs do
			local d=(slab.part.Position-desired).Magnitude
			if not used[slab] and d<distance then best=slab; distance=d end
		end
		assert(best,"Not enough separate stones for spawns"); used[best]=true
		local pos=best.part.Position+Vector3.new(0,6,0)
		points[i]=CFrame.lookAt(pos,Vector3.new(0,pos.Y,0))
	end
	return points
end
function Arena:LobbyCFrame(index) return self.spawn*CFrame.new(((index or 1)-1)%5*3-6,0,0) end
return Arena
