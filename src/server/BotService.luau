--!nonstrict
local CollectionService=game:GetService("CollectionService")
local Config=require(game:GetService("ReplicatedStorage").Shared.Config)
local U=require(script.Parent.Util)
local G=require(script.Parent.Geometry)
local Bots={}; Bots.__index=Bots
local names={"Cassius","Flavia","Aurelia","Marcus","Lucius","Octavia","Titus"}
function Bots.new(round,arena,combat,items)
	local folder=Instance.new("Folder"); folder.Name="ArenaBots"; folder.Parent=arena.world
	return setmetatable({round=round,arena=arena,combat=combat,items=items,folder=folder,bots={},nextThink=0},Bots)
end
local function motor(parent,name,a,b,c0,c1)
	local joint=Instance.new("Motor6D"); joint.Name=name; joint.Part0=a; joint.Part1=b
	joint.C0=c0; joint.C1=c1; joint.Parent=parent; return joint
end
function Bots:Create(index)
	local rig=Instance.new("Model"); rig.Name="Gladiator_"..index
	rig.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
	rig:SetAttribute("DisplayName",names[index] or "Gladiator"); rig:SetAttribute("Bot",true)
	rig:SetAttribute("ActorId",1000000+index)
	local at=CFrame.new(0,75,0)
	local skin=({Color3.fromRGB(136,94,65),Color3.fromRGB(185,134,94),Color3.fromRGB(92,63,42)})[(index-1)%3+1]
	local tunic=({Color3.fromRGB(117,49,40),Color3.fromRGB(71,85,84),Color3.fromRGB(113,95,60)})[(index-1)%3+1]
	local function limb(name,size,offset,color)
		local p=U.part(rig,name,size,at*offset,color,Enum.Material.SmoothPlastic)
		p.Anchored=false; p.CanCollide=false; p.CanTouch=false; return p
	end
	local root=limb("HumanoidRootPart",Vector3.new(2,2,1),CFrame.identity,skin); root.Transparency=1; root.RootPriority=100
	local torso=limb("Torso",Vector3.new(2,2,1),CFrame.identity,tunic); torso.CanCollide=true
	local head=limb("Head",Vector3.new(2,1,1),CFrame.new(0,1.5,0),skin)
	local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.Head; mesh.Scale=Vector3.new(1.1,1.1,1.1); mesh.Parent=head
	for _,side in {-1,1} do
		local eye=U.part(rig,"Eye",Vector3.new(.15,.12,.045),head.CFrame*CFrame.new(side*.32,.03,-.54),Color3.fromRGB(33,29,25),Enum.Material.SmoothPlastic)
		eye.CanCollide=false; eye.CanQuery=false; eye.Massless=true; U.weld(head,eye)
	end
	motor(root,"RootJoint",root,torso,CFrame.identity,CFrame.identity)
	motor(torso,"Neck",torso,head,CFrame.new(0,1,0),CFrame.new(0,-.5,0))
	for _,side in {-1,1} do
		local word=if side<0 then "Left" else "Right"
		local arm=limb(word.." Arm",Vector3.new(1,2,1),CFrame.new(side*1.5,0,0),skin)
		local leg=limb(word.." Leg",Vector3.new(1,2,1),CFrame.new(side*.5,-2,0),Color3.fromRGB(89,62,43))
		motor(torso,word.." Shoulder",torso,arm,CFrame.new(side,.5,0),CFrame.new(-side*.5,.5,0))
		motor(torso,word.." Hip",torso,leg,CFrame.new(side*.5,-1,0),CFrame.new(0,1,0))
	end
	local helmet=G.cylinder(rig,"BronzeHelmet",.76,.55,at*CFrame.new(0,1.9,0),Color3.fromRGB(130,105,63),Enum.Material.Metal)
	helmet.CanCollide=false; helmet.CanQuery=false; helmet.Massless=true; U.weld(head,helmet)
	local crest=U.part(rig,"HelmetCrest",Vector3.new(.22,.65,1.3),at*CFrame.new(0,2.45,0),tunic,Enum.Material.Fabric)
	crest.CanCollide=false; crest.CanQuery=false; crest.Massless=true; U.weld(head,crest)
	local belt=U.part(rig,"LeatherBelt",Vector3.new(2.06,.28,1.05),at*CFrame.new(0,-.68,0),Color3.fromRGB(62,43,32),Enum.Material.Fabric)
	belt.CanCollide=false; belt.CanQuery=false; belt.Massless=true; U.weld(torso,belt)
	local humanoid=Instance.new("Humanoid"); humanoid.DisplayName=(names[index] or "Gladiator").." · NPC"
	humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.Viewer; humanoid.NameDisplayDistance=35
	humanoid.HealthDisplayType=Enum.HumanoidHealthDisplayType.AlwaysOff; humanoid.BreakJointsOnDeath=false
	humanoid.WalkSpeed=Config.Bots.WalkSpeed; humanoid.UseJumpPower=true; humanoid.JumpPower=45; humanoid.HipHeight=0
	humanoid.Parent=rig; rig.PrimaryPart=root; rig.Parent=self.folder
	root:SetNetworkOwner(nil); CollectionService:AddTag(rig,"ArenaBot")
	table.insert(self.bots,{model=rig,nextPush=os.clock()+2+math.random(),nextJump=0,nextItem=0})
	humanoid.Died:Connect(function() self.round:Eliminate(rig) end)
	return rig
end
function Bots:Clear()
	for _,bot in self.bots do self.combat:Forget(bot.model); bot.model:Destroy() end
	table.clear(self.bots); self.nextThink=0
end
function Bots:Step()
	if os.clock()<self.nextThink then return end
	self.nextThink=os.clock()+Config.Bots.ThinkInterval
	local active=self.round:Active()
	for _,bot in self.bots do
		local actor=bot.model
		if not self.round:IsActive(actor) then continue end
		local root,hum=U.root(actor)
		if not root or hum.PlatformStand or root.Anchored then continue end

		local target,distance=nil,math.huge
		local selfRadius=Vector3.new(root.Position.X-Config.Arena.Center.X,0,root.Position.Z-Config.Arena.Center.Z).Magnitude
		for _,other in active do
			if other==actor or not self.combat:Enemy(actor,other) then continue end
			local otherRoot=U.root(other)
			if not otherRoot then continue end
			local d=(otherRoot.Position-root.Position).Magnitude
			if d<distance then target=otherRoot; distance=d end
		end

		local under=self.arena:Under(root)
		local desired=target and target.Position or Config.Arena.Center
		local targetRadius=target and Vector3.new(target.Position.X-Config.Arena.Center.X,0,target.Position.Z-Config.Arena.Center.Z).Magnitude or 0
		local danger=selfRadius>Config.Arena.Radius*.79 or not under or (under and under.stress/under.durability>.70)

		if danger then
			-- Recover toward a healthier inner slab instead of blindly chasing over an edge.
			local best=math.huge
			for _,slab in self.arena.slabs do
				if slab.broken then continue end
				local radial=Vector3.new(slab.part.Position.X-Config.Arena.Center.X,0,slab.part.Position.Z-Config.Arena.Center.Z).Magnitude
				if radial>Config.Arena.Radius*.70 then continue end
				local score=(slab.part.Position-root.Position).Magnitude+slab.stress/slab.durability*52+radial*.08
				if score<best then best=score; desired=slab.part.Position end
			end
		elseif target then
			local toTarget=Vector3.new(target.Position.X-root.Position.X,0,target.Position.Z-root.Position.Z)
			local radialOut=Vector3.new(target.Position.X-Config.Arena.Center.X,0,target.Position.Z-Config.Arena.Center.Z)
			-- When an opponent is near the rim, approach from the inside so pushes send them outward.
			if targetRadius>Config.Arena.Radius*.68 and radialOut.Magnitude>.1 then
				desired=target.Position-radialOut.Unit*6
			elseif distance<13 and toTarget.Magnitude>.1 then
				-- Small side-step keeps bots from forming a single robotic line.
				local side=Vector3.new(-toTarget.Z,0,toTarget.X).Unit
				local sign=if (bot.model:GetAttribute("ActorId") or 0)%2==0 then 1 else -1
				desired=target.Position+side*sign*3.5
			end
		end

		local threat=self.round.hazards and self.round.hazards:ThreatAt(root.Position) or Vector3.zero
		if threat.Magnitude>.1 then desired=root.Position+threat.Unit*16 end
		local goal=Vector3.new(desired.X-root.Position.X,0,desired.Z-root.Position.Z)
		if goal.Magnitude<.1 then goal=Vector3.zAxis end
		goal=goal.Unit

		local heading=nil; local score=-math.huge; local jump=false
		for i=0,15 do
			local a=i/16*math.pi*2
			local dir=Vector3.new(math.sin(a),0,math.cos(a))
			local near=self.arena:GroundAt(root.Position+dir*4+Vector3.new(0,5,0),22)
			local far=self.arena:GroundAt(root.Position+dir*10+Vector3.new(0,7,0),28)
			if not near or not far then continue end
			local future=root.Position+dir*10
			local futureRadius=Vector3.new(future.X-Config.Arena.Center.X,0,future.Z-Config.Arena.Center.Z).Magnitude
			local edgePenalty=math.max(0,(futureRadius-Config.Arena.Radius*.72)/(Config.Arena.Radius*.2))*5
			local value=dir:Dot(goal)*3.5-far.stress/far.durability*2.6-edgePenalty
			if value>score then score=value; heading=dir end
		end

		if not heading and os.clock()>bot.nextJump then
			local landing=self.arena:GroundAt(root.Position+goal*10+Vector3.new(0,7,0),28)
			if landing then heading=goal; jump=true; bot.nextJump=os.clock()+2.2 end
		end
		hum:Move(heading or Vector3.zero,false)
		if jump then hum.Jump=true end
		if self.round.movement and heading then
			if threat.Magnitude>8 then self.round.movement:Dash(actor,heading) end
			if (actor:GetAttribute("Adrenaline") or 0)>=100 then self.round.movement:Adrenaline(actor) end
		end

		if target and distance<=Config.Combat.Range and os.clock()>bot.nextPush then
			local targetOut=Vector3.new(target.Position.X-Config.Arena.Center.X,0,target.Position.Z-Config.Arena.Center.Z)
			local look=Vector3.new(target.Position.X,root.Position.Y,target.Position.Z)
			if (look-root.Position).Magnitude>.1 then root.CFrame=CFrame.lookAt(root.Position,look) end
			local goodPush=targetOut.Magnitude>Config.Arena.Radius*.62
			bot.nextPush=os.clock()+Config.Bots.PushCooldown+math.random()*.45
			if goodPush or math.random()<.72 then self.combat:Push(actor) else self.combat:Grab(actor) end
		end

		if under and self.items:FirstEmpty(actor) and under.pickup then
			self.items:Pickup(actor,under,under.pickup,under.pickup:GetAttribute("ItemId"))
		end
		if actor:GetAttribute("Item") and os.clock()>bot.nextItem then
			bot.nextItem=os.clock()+.85+math.random()*.8
			local id=actor:GetAttribute("Item")
			local useNow=if id=="Sword" then distance<Config.Combat.SwordRange
				elseif id=="Mace" then distance<Config.Combat.MaceRange
				elseif id=="Bow" then distance<65
				elseif id=="Ram" then distance<10
				elseif id=="Brace" then under and under.stress/under.durability>.4
				elseif id=="Shield" then distance<14 and (actor:GetAttribute("ShieldUntil") or 0)<workspace:GetServerTimeNow()
				else distance<18
			if useNow then self.items:Use(actor,if target then (target.Position-root.Position).Unit else goal) end
		end
	end
end
return Bots
