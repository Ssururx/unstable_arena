--!nonstrict
-- Original stylized quadruped: rounded anatomy, articulated legs and tail.
local U=require(script.Parent.Util)
local CollectionService=game:GetService("CollectionService")
local Lion={}
function Lion.create(parent,cf,index)
	local rig=Instance.new("Model"); rig.Name="ArenaLion_"..index
	rig.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
	local coat=Color3.fromRGB(171,126,73)
	local maneColor=Color3.fromRGB(94,61,36)
	local root=U.part(rig,"HumanoidRootPart",Vector3.new(2,2,3),cf)
	root.Transparency=1; root.CanCollide=false; root.RootPriority=100
	local function ellipsoid(name,size,offset,color,parentPart)
		local part=U.part(rig,name,size,cf*offset,color,Enum.Material.SmoothPlastic)
		part.CanCollide=false; part.CanTouch=false; part.Massless=true
		local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.Sphere; mesh.Parent=part
		if parentPart~=false then U.weld(parentPart or root,part) end
		return part
	end
	local body=ellipsoid("Body",Vector3.new(3.1,2.5,5.2),CFrame.identity,coat)
	body.CanCollide=true; body.Massless=false
	ellipsoid("Haunches",Vector3.new(3.3,2.7,2.8),CFrame.new(0,0,1.5),coat)
	ellipsoid("Chest",Vector3.new(3.3,3.0,2.8),CFrame.new(0,.2,-1.55),coat)
	ellipsoid("Mane",Vector3.new(3.7,3.9,2.9),CFrame.new(0,.65,-2.35),maneColor)
	-- Uneven tufts give the mane a silhouette without a block-shaped head.
	for i=0,9 do
		local a=i/10*math.pi*2
		ellipsoid("ManeTuft",Vector3.new(.75,1.4,.9),CFrame.new(math.sin(a)*1.5,.6+math.cos(a)*1.55,-2.5)*CFrame.Angles(0,0,-a),maneColor:Lerp(coat,(i%3)*.05))
	end
	ellipsoid("Head",Vector3.new(2.25,2.15,2.15),CFrame.new(0,.85,-3.35),coat)
	for _,side in {-1,1} do
		ellipsoid("Ear",Vector3.new(.62,.73,.32),CFrame.new(side*.88,1.95,-3.25),coat)
		ellipsoid("EarInner",Vector3.new(.32,.40,.15),CFrame.new(side*.88,1.97,-3.44),maneColor)
		ellipsoid("Muzzle",Vector3.new(.85,.72,.85),CFrame.new(side*.32,.32,-4.28),Color3.fromRGB(213,183,133))
		ellipsoid("Eye",Vector3.new(.22,.19,.12),CFrame.new(side*.65,1.15,-4.20),Color3.fromRGB(29,24,17))
	end
	ellipsoid("Nose",Vector3.new(.48,.27,.25),CFrame.new(0,.52,-4.66),Color3.fromRGB(43,31,26))
	local function joint(name,part,offset)
		local motor=Instance.new("Motor6D"); motor.Name=name; motor.Part0=root; motor.Part1=part
		motor.C0=offset; motor.C1=part.CFrame:ToObjectSpace(cf*offset); motor.Parent=root
		part.Anchored=false; return motor
	end
	for _,side in {-1,1} do
		for _,front in {-1,1} do
			local leg=ellipsoid("Leg",Vector3.new(.76,2.3,.88),CFrame.new(side*1.05,-1.45,front*1.65),coat,false)
			ellipsoid("Paw",Vector3.new(1,.50,1.3),CFrame.new(side*1.05,-2.45,front*1.65-.18),Color3.fromRGB(151,108,59),leg)
			joint("LionLeg_"..side.."_"..front,leg,CFrame.new(side*1.05,-.4,front*1.65))
		end
	end
	local tail=ellipsoid("Tail",Vector3.new(.24,.26,3.3),CFrame.new(0,.2,3.65)*CFrame.Angles(-.24,0,0),coat,false)
	ellipsoid("TailTuft",Vector3.new(.53,.53,.85),CFrame.new(0,.55,5.2),maneColor,tail)
	joint("LionTail",tail,CFrame.new(0,.2,2.15))
	local hum=Instance.new("Humanoid"); hum.RequiresNeck=false; hum.BreakJointsOnDeath=false
	hum.HipHeight=1.65; hum.WalkSpeed=21; hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
	hum.Parent=rig; rig.PrimaryPart=root; rig.Parent=parent; root.Anchored=false; root:SetNetworkOwner(nil)
	CollectionService:AddTag(rig,"ArenaLion")
	return rig
end
return Lion
