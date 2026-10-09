--!nonstrict
-- Original procedural clips. No third-party asset permissions or uploads required.
-- Restore our last layer BEFORE Animator evaluates; layer AFTER it evaluates.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local CollectionService=game:GetService("CollectionService")
local WeaponPoses=require(script.Parent.WeaponPoses)
local Animation={}
local ID=CFrame.identity
local function pose(x,y,z) return CFrame.Angles(math.rad(x),math.rad(y or 0),math.rad(z or 0)) end
local function envelope(now,finish,duration)
	local t=1-(finish-now)/duration
	if t<0 or t>1 then return 0,0 end
	return t,math.min(1,t/.12,(1-t)/.24)
end
function Animation.start()
	local rigs={}
	local function add(character,actor)
		if rigs[character] then return end
		local data={actor=actor,joints={},connections={},phase=0}
		rigs[character]=data
		local function joint(d)
			if not d:IsA("Motor6D") and not d:IsA("AnimationConstraint") then return end
			local name=d.Name:lower():gsub("%s","")
			local role=if name:find("rightshoulder") then "right"
				elseif name:find("leftshoulder") then "left"
				elseif name:find("rightelbow") then "rightElbow"
				elseif name:find("leftelbow") then "leftElbow"
				elseif name:find("righthip") then "rightHip"
				elseif name:find("lefthip") then "leftHip"
				elseif name:find("rightknee") then "rightKnee"
				elseif name:find("leftknee") then "leftKnee"
				elseif name=="weapongrip" then "grip"
				elseif name=="rootjoint" or name=="root" then "body" else nil
			if role then data.joints[d]={role=role,base=ID,applied=false} end
		end
		for _,d in character:GetDescendants() do joint(d) end
		table.insert(data.connections,character.DescendantAdded:Connect(joint))
	end
	local function remove(character)
		local data=rigs[character]; if not data then return end
		for _,c in data.connections do c:Disconnect() end
		for joint,info in data.joints do if joint.Parent and info.applied then joint.Transform=info.base end end
		rigs[character]=nil
	end
	local function player(p)
		p.CharacterAdded:Connect(function(c) add(c,p) end)
		p.CharacterRemoving:Connect(remove)
		if p.Character then add(p.Character,p) end
	end
	Players.PlayerAdded:Connect(player)
	for _,p in Players:GetPlayers() do player(p) end
	for _,bot in CollectionService:GetTagged("ArenaBot") do add(bot,bot) end
	CollectionService:GetInstanceAddedSignal("ArenaBot"):Connect(function(bot) add(bot,bot) end)
	CollectionService:GetInstanceRemovedSignal("ArenaBot"):Connect(remove)
	RunService.PreAnimation:Connect(function()
		for character,data in rigs do
			if not character.Parent then remove(character); continue end
			for joint,info in data.joints do
				if not joint.Parent then data.joints[joint]=nil
				elseif info.applied then joint.Transform=info.base; info.applied=false end
			end
		end
	end)
	RunService.PreSimulation:Connect(function(dt)
		local now=workspace:GetServerTimeNow()
		local camera=workspace.CurrentCamera
		for character,data in rigs do
			local root=character:FindFirstChild("HumanoidRootPart")
			local hum=character:FindFirstChildOfClass("Humanoid")
			if not root or not hum or hum.Health<=0 or hum.PlatformStand then continue end
			if camera and (root.Position-camera.CFrame.Position).Magnitude>500 then continue end
			local actor=data.actor
			local velocity=root.AssemblyLinearVelocity
			local speed=Vector3.new(velocity.X,0,velocity.Z).Magnitude
			data.phase+=math.min(speed,30)*dt*.52
			local offsets={}; local weights={}; local overrides={}
			local function set(role,cf,w,absolute) offsets[role]=cf; weights[role]=w or 1; overrides[role]=absolute==true end
			if actor:GetAttribute("Bot") then
				local stride=math.sin(data.phase)*math.clamp(speed/18,0,1)*.58
				set("rightHip",CFrame.Angles(stride,0,0)); set("leftHip",CFrame.Angles(-stride,0,0))
				set("left",CFrame.Angles(stride*.6,0,-.08)); set("right",CFrame.Angles(-stride*.6,0,.08))
				set("body",CFrame.new(0,math.abs(math.sin(data.phase))*.055,0))
			end
			local item=actor:GetAttribute("Item")
			if item=="Sword" or item=="Mace" or item=="Ram" then
				set("right",pose(25,-12,16),.85,true); set("rightElbow",pose(35),.85,true)
			elseif item=="Bow" then
				set("left",pose(35,0,-12),.7); set("right",pose(30,0,12),.7)
			end
			if item=="Shield" or (actor:GetAttribute("ShieldUntil") or 0)>now then
				set("left",pose(65,-20,-15),.9); set("leftElbow",pose(55),.9)
			end
			local t,w=envelope(now,actor:GetAttribute("SwingUntil") or 0,.40)
			if w>0 then
				local extend=math.clamp((t-.18)/.22,0,1)
				set("right",pose(30+55*extend,0,8),w,true); set("left",pose(30+55*extend,0,-8),w,true)
				set("rightElbow",pose(60*(1-extend)),w,true); set("leftElbow",pose(60*(1-extend)),w,true)
				set("body",pose(-8*extend),w,true)
				set("rightHip",pose(-12,0,5),w,true); set("leftHip",pose(-12,0,-5),w,true)
			end
			t,w=envelope(now,actor:GetAttribute("GrabUntil") or 0,.52)
			if w>0 then
				local pull=math.clamp((t-.3)/.4,0,1)
				set("right",pose(85-55*pull,0,12),w); set("left",pose(75-50*pull,0,-12),w)
				set("rightElbow",pose(80*pull),w); set("leftElbow",pose(80*pull),w)
				set("body",pose(10*pull),w)
			end
			t,w=envelope(now,actor:GetAttribute("ItemActionUntil") or 0,actor:GetAttribute("ItemActionDuration") or .55)
			if w>0 then
				local kind=actor:GetAttribute("ItemActionKind")
				if kind=="Sword" or kind=="Mace" then
					for role,cf in WeaponPoses.sample(kind,t,(actor:GetAttribute("AttackIndex") or 0)%2==0) do
						set(role,cf,w,true)
					end
				elseif kind=="Bow" then
					set("left",pose(90,-65,-6),w); set("right",pose(70,65,10),w)
					set("rightElbow",pose(105*(1-math.clamp((t-.55)*4,0,1))),w)
					set("body",pose(0,-30,0),w)
				elseif kind=="Ram" then
					local strike=math.clamp((t-.45)/.25,0,1)
					set("right",pose(150-85*strike,-20,22),w); set("body",pose(10-22*strike,20-35*strike,0),w)
				elseif kind=="Shield" then set("left",pose(90,-15,-18),w)
				else
					set("right",pose(55,0,15),w); set("body",pose(-12),w)
				end
			end
			local fighting=math.max(actor:GetAttribute("SwingUntil") or 0,actor:GetAttribute("ItemActionUntil") or 0,actor:GetAttribute("GrabUntil") or 0)>now
			t,w=envelope(now,actor:GetAttribute("SlidingUntil") or 0,.72)
			if w>0 and not fighting then
				set("body",CFrame.new(0,-.85,0)*pose(30),w)
				set("rightHip",pose(-55,0,8),w); set("leftHip",pose(-25,0,-8),w)
				set("rightKnee",pose(-70),w); set("leftKnee",pose(-105),w)
				set("right",pose(-18,0,25),w); set("left",pose(-18,0,-25),w)
			elseif not fighting and (actor:GetAttribute("DashUntil") or 0)>now then set("body",pose(-18),.8) end
			for joint,info in data.joints do
				local offset=offsets[info.role]
				if offset and joint.Parent then
					info.base=joint.Transform
					-- Convert an anatomical part-space pose into this rig's joint axes.
					local basis=ID
					if joint:IsA("Motor6D") then basis=joint.C1.Rotation
					elseif joint.Attachment1 then basis=joint.Attachment1.CFrame.Rotation end
					local target=basis:Inverse()*offset*basis
					local weight=weights[info.role] or 1
					-- Combat owns its arm joints; adding to a walk swing cancels one arm.
					if overrides[info.role] then joint.Transform=info.base:Lerp(target,weight)
					else joint.Transform=info.base*ID:Lerp(target,weight) end
					info.applied=true
				end
			end
			local held=character:FindFirstChild("HeldArenaItem")
			local trail=held and held:FindFirstChild("BladeTrail",true)
			if trail then trail.Enabled=(actor:GetAttribute("ItemActionKind")=="Sword") and (actor:GetAttribute("ItemActionUntil") or 0)-now>.13 and (actor:GetAttribute("ItemActionUntil") or 0)-now<.4 end
		end
	end)
	local lions={}
	local function addLion(model)
		local joints={}
		for _,d in model:GetDescendants() do if d:IsA("Motor6D") then table.insert(joints,d) end end
		lions[model]={joints=joints,phase=0}
	end
	for _,lion in CollectionService:GetTagged("ArenaLion") do addLion(lion) end
	CollectionService:GetInstanceAddedSignal("ArenaLion"):Connect(addLion)
	CollectionService:GetInstanceRemovedSignal("ArenaLion"):Connect(function(model) lions[model]=nil end)
	RunService.PreSimulation:Connect(function(dt)
		for model,data in lions do
			local root=model:FindFirstChild("HumanoidRootPart")
			if not root then continue end
			local v=root.AssemblyLinearVelocity
			local speed=Vector3.new(v.X,0,v.Z).Magnitude
			data.phase+=math.min(speed,25)*dt*.6
			for _,joint in data.joints do
				if not joint.Parent then continue end
				if joint.Name=="LionTail" then joint.Transform=pose(0,math.sin(data.phase*.35)*15,0)
				else
					local side,front=joint.Name:match("LionLeg_([%-0-9]+)_([%-0-9]+)")
					local offset=if tonumber(side)==tonumber(front) then 0 else math.pi
					joint.Transform=pose(math.sin(data.phase+offset)*32*math.clamp(speed/18,0,1))
				end
			end
		end
	end)

end
return Animation
