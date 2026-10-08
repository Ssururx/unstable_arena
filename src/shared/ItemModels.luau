--!nonstrict
-- Original, script-free models shared by pickups, held equipment and hotbar previews.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Models={}

local function connected(handle,part,root)
	for _,d in root:GetDescendants() do
		if d:IsA("WeldConstraint") and ((d.Part0==handle and d.Part1==part) or (d.Part1==handle and d.Part0==part)) then
			return true
		end
	end
	return false
end

local function attachImported(root,id,preview)
	if id~="Sword" and id~="Mace" then return false end
	local folder=ReplicatedStorage:FindFirstChild("WeaponMeshes")
	local template=folder and folder:FindFirstChild(id)
	if not template then return false end
	local clone=template:Clone()
	clone.Name=id.."Mesh"
	clone.Parent=root

	local handle=if clone:IsA("BasePart") then clone else clone:FindFirstChild("Handle",true)
	if not handle or not handle:IsA("BasePart") then
		warn("[UnstableArena] "..id.." mesh template needs exactly one BasePart named Handle")
		clone:Destroy(); return false
	end
	local grip=template:GetAttribute("GripOffset")
	if typeof(grip)~="CFrame" then grip=CFrame.identity end

	local parts={}
	if clone:IsA("BasePart") then table.insert(parts,clone) end
	for _,d in clone:GetDescendants() do if d:IsA("BasePart") then table.insert(parts,d) end end
	for _,d in parts do
		d.CanCollide=false; d.CanTouch=false; d.CanQuery=false; d.Massless=true
		d.Anchored=preview==true
	end
	if clone:IsA("BasePart") then
		clone.CFrame=root.CFrame*grip
	elseif clone:IsA("Model") then
		clone:PivotTo(root.CFrame*grip)
	end

	if not preview then
		if clone:IsA("Model") then
			for _,d in clone:GetDescendants() do
				if d:IsA("BasePart") and d~=handle and not connected(handle,d,clone) then
					local weld=Instance.new("WeldConstraint"); weld.Part0=handle; weld.Part1=d; weld.Parent=d
				end
			end
		end
		local gripWeld=Instance.new("WeldConstraint"); gripWeld.Part0=root; gripWeld.Part1=handle; gripWeld.Parent=handle
	end
	return true
end

local bronze=Color3.fromRGB(160,120,62)
local edge=Color3.fromRGB(207,174,108)
local iron=Color3.fromRGB(65,70,72)
local steel=Color3.fromRGB(191,201,201)
local leather=Color3.fromRGB(64,40,29)
local wood=Color3.fromRGB(111,74,43)
function Models.attach(root,id,preview)
	local function piece(name,size,cf,color,material,shape)
		local p=Instance.new("Part"); p.Name=name; p.Size=size
		p.CFrame=root.CFrame*cf; p.Color=color; p.Material=material or Enum.Material.Metal
		p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
		p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.Massless=true
		if shape then p.Shape=shape end
		p.Anchored=preview==true; p.Parent=root
		if not preview then local w=Instance.new("WeldConstraint"); w.Part0=root; w.Part1=p; w.Parent=p end
		return p
	end
	local function bar(name,from,to,width,color)
		local delta=to-from
		local up=if math.abs(delta.Unit:Dot(Vector3.yAxis))>.98 then Vector3.zAxis else Vector3.yAxis
		return piece(name,Vector3.new(width,width,delta.Magnitude),CFrame.lookAt((from+to)/2,to,up),color)
	end
	local function ball(name,size,position,color)
		return piece(name,size,CFrame.new(position),color,Enum.Material.Metal,Enum.PartType.Ball)
	end
	local function disk(name,radius,depth,cf,color)
		return piece(name,Vector3.new(depth,radius*2,radius*2),cf*CFrame.Angles(0,math.pi/2,0),color,Enum.Material.Metal,Enum.PartType.Cylinder)
	end
	if id=="Sword" then
		if attachImported(root,id,preview) then return end
		piece("LeatherGrip",Vector3.new(.25,.85,.28),CFrame.new(0,-.48,0),leather,Enum.Material.Fabric)
		for i=0,5 do piece("GripWrap",Vector3.new(.28,.055,.3),CFrame.new(0,-.82+i*.12,0),wood) end
		ball("Pommel",Vector3.new(.45,.3,.38),Vector3.new(0,-1,0),bronze)
		piece("Guard",Vector3.new(.85,.22,.42),CFrame.new(0,-.02,0),bronze)
		piece("Blade",Vector3.new(.48,2.3,.12),CFrame.new(0,1.22,0),steel)
		piece("BladeRidge",Vector3.new(.085,2.22,.15),CFrame.new(0,1.22,0),Color3.fromRGB(225,229,225))
		-- Two bevelled edges taper to a pointed tip.
		for _,side in {-1,1} do
			local tip=piece("BladeTip",Vector3.new(.12,.65,.24),CFrame.new(side*.12,2.69,0)*CFrame.Angles(0,-side*math.pi/2,0),steel)
			local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.Wedge; mesh.Parent=tip
			bar("BladeEdge",Vector3.new(side*.24,.1,0),Vector3.new(side*.24,2.36,0),.045,Color3.fromRGB(229,234,229))
		end
	elseif id=="Shield" then
		piece("Scutum",Vector3.new(1.9,2.75,.21),CFrame.identity,Color3.fromRGB(109,36,31),Enum.Material.Wood)
		for _,side in {-1,1} do
			piece("CurvedShieldWing",Vector3.new(.38,2.65,.2),CFrame.new(side*1.06,0,.10)*CFrame.Angles(0,-side*.35,0),Color3.fromRGB(109,36,31),Enum.Material.Wood)
			piece("ShieldRim",Vector3.new(.10,2.8,.25),CFrame.new(side*1.23,0,.15),bronze)
			piece("ShieldRim",Vector3.new(2.5,.10,.25),CFrame.new(0,side*1.36,0),bronze)
			bar("WingEmblem",Vector3.new(0,0,-.15),Vector3.new(side*.78,.7,-.15),.075,edge)
			bar("WingEmblem",Vector3.new(0,0,-.15),Vector3.new(side*.78,-.7,-.15),.075,edge)
		end
		disk("BossRim",.43,.09,CFrame.new(0,0,-.18),bronze)
		ball("ShieldBoss",Vector3.new(.64,.64,.34),Vector3.new(0,0,-.27),iron)
	elseif id=="Mace" then
		if attachImported(root,id,preview) then return end
		piece("MaceGrip",Vector3.new(.30,1.55,.30),CFrame.new(0,-.35,0),leather)
		for _,y in {-.98,.38} do ball("GripCap",Vector3.new(.40,.20,.40),Vector3.new(0,y,0),bronze) end
		for i=1,5 do
			-- Four bars per alternating chain link, with actual gaps.
			local cf=CFrame.new(0,.45+i*.20,0)*CFrame.Angles(0,if i%2==0 then math.pi/2 else 0,0)
			for _,s in {-1,1} do
				piece("ChainLink",Vector3.new(.06,.25,.06),cf*CFrame.new(s*.10,0,0),iron)
				piece("ChainLink",Vector3.new(.22,.06,.06),cf*CFrame.new(0,s*.125,0),iron)
			end
		end
		ball("MaceHead",Vector3.one*1.05,Vector3.new(0,1.97,0),iron)
		for i=0,5 do
			local a=i/6*math.pi*2
			piece("MaceFlange",Vector3.new(.18,.75,.48),CFrame.new(math.cos(a)*.47,1.97,math.sin(a)*.47)*CFrame.Angles(0,-a,0),bronze)
		end
	elseif id=="Bow" then
		local last=nil
		for i=0,12 do
			local a=-math.pi/2+i/12*math.pi
			local p=Vector3.new(math.cos(a)*.85-.3,math.sin(a)*1.55,0)
			if last then bar("BowLimb",last,p,.12,wood) end
			last=p
		end
		bar("BowString",Vector3.new(-.3,-1.55,0),Vector3.new(-.3,1.55,0),.025,Color3.fromRGB(210,193,158))
		piece("BowGrip",Vector3.new(.20,.56,.22),CFrame.new(.53,0,0),leather)
	elseif id=="Anchor" then
		bar("AnchorStem",Vector3.new(0,-.8,0),Vector3.new(0,1.1,0),.23,iron)
		bar("AnchorStock",Vector3.new(-.8,.45,0),Vector3.new(.8,.45,0),.22,bronze)
		for _,s in {-1,1} do bar("AnchorFluke",Vector3.new(0,-.8,0),Vector3.new(s*.9,-.35,0),.25,iron) end
	elseif id=="Ram" then
		piece("RamHandle",Vector3.new(.28,2,.28),CFrame.new(0,-.35,0),wood,Enum.Material.Wood)
		piece("RamHead",Vector3.new(1.95,.82,.90),CFrame.new(0,.85,0),iron)
		for _,s in {-1,1} do piece("RamCap",Vector3.new(.20,.92,1),CFrame.new(s*.90,.85,0),bronze) end
	elseif id=="Brace" then
		for _,s in {-1,1} do piece("Timber",Vector3.new(.45,2.1,.4),CFrame.Angles(0,0,s*.45),wood,Enum.Material.Wood) end
		piece("Binding",Vector3.new(1.55,.3,.48),CFrame.identity,leather)
	else
		piece("Weight",Vector3.new(1.6,1.35,1.5),CFrame.identity,iron,Enum.Material.Slate)
		piece("WeightBand",Vector3.new(1.66,.25,1.56),CFrame.identity,bronze)
		bar("Handle",Vector3.new(-.35,.95,0),Vector3.new(.35,.95,0),.14,bronze)
		for _,s in {-1,1} do bar("HandleLeg",Vector3.new(s*.35,.65,0),Vector3.new(s*.35,.95,0),.14,bronze) end
	end
end
return Models
