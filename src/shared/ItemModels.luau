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
	local function triangle(name,a,b,c,color)
		local ab,ac,bc=b-a,c-a,c-b
		if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then c,a=a,c
		elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
		ab,ac,bc=b-a,c-a,c-b
		local normal=ac:Cross(ab); if normal.Magnitude<.00001 then return end
		local right=normal.Unit; local back=bc.Unit; local up=back:Cross(right).Unit
		local height=math.abs(ab:Dot(up))
		for _,spec in {{(a+b)/2,right,back,math.abs(ab:Dot(back))},{(a+c)/2,-right,-back,math.abs(ac:Dot(back))}} do
			if spec[4]<.005 or height<.005 then continue end
			local p=Instance.new("WedgePart"); p.Name=name; p.Size=Vector3.new(.018,height,spec[4])
			p.CFrame=root.CFrame*CFrame.fromMatrix(spec[1],spec[2],up,spec[3]); p.Color=color; p.Material=Enum.Material.Metal
			p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.Massless=true; p.Anchored=preview==true
			p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth; p.Parent=root
			if not preview then local w=Instance.new("WeldConstraint"); w.Part0=root; w.Part1=p; w.Parent=p end
		end
	end
	local function spindle(name,length,radius,cf,color)
		return piece(name,Vector3.new(length,radius*2,radius*2),cf*CFrame.Angles(0,0,math.pi/2),color,Enum.Material.Metal,Enum.PartType.Cylinder)
	end
	local function maceHead(center)
		ball("MaceHead",Vector3.one*1.05,center,iron)
		for _,y in {-.37,.37} do spindle("HeadBand",.10,.45,CFrame.new(center+Vector3.new(0,y,0)),bronze) end
		for i=0,7 do
			local angle=i/8*math.pi*2
			local radial=Vector3.new(math.cos(angle),0,math.sin(angle))
			local tangent=Vector3.new(-math.sin(angle),0,math.cos(angle))*.08
			local base=center+radial*.38
			local tip=center+radial*.82
			for _,side in {-1,1} do
				triangle("MaceFlange",base+Vector3.new(0,-.39,0)+tangent*side,base+Vector3.new(0,.39,0)+tangent*side,tip+tangent*side,if i%2==0 then bronze else steel)
			end
		end
	end
	if id=="Sword" then
		if attachImported(root,id,preview) then return end
		spindle("LeatherGrip",.92,.155,CFrame.new(0,-.55,0),leather)
		for i=0,7 do
			spindle("GripWrap",.035,.172,CFrame.new(0,-.94+i*.115,0)*CFrame.Angles(.07,0,.10),wood)
		end
		ball("Pommel",Vector3.new(.5,.32,.4),Vector3.new(0,-1.13,0),bronze)
		disk("PommelSeal",.12,.035,CFrame.new(0,-1.13,-.2),edge)
		ball("Guard",Vector3.new(1.05,.28,.48),Vector3.new(0,-.06,0),bronze)
		for _,side in {-1,1} do ball("GuardFinial",Vector3.one*.23,Vector3.new(side*.47,-.05,0),edge) end
		spindle("BladeCollar",.20,.21,CFrame.new(0,.10,0),bronze)
		-- A leaf-shaped, diamond-section blade with real bevel planes, not a rectangular bar.
		local sections={{.18,.23,.075},{.70,.31,.095},{2.15,.235,.07},{2.92,0,0}}
		local function cross(section)
			return {Vector3.new(-section[2],section[1],0),Vector3.new(0,section[1],-section[3]),Vector3.new(section[2],section[1],0),Vector3.new(0,section[1],section[3])}
		end
		for i=1,#sections-1 do
			local lower,upper=cross(sections[i]),cross(sections[i+1])
			for j=1,4 do
				local k=j%4+1
				local color=if j%2==0 then steel else Color3.fromRGB(224,231,229)
				triangle("BladeBevel",lower[j],lower[k],upper[k],color)
				triangle("BladeBevel",lower[j],upper[k],upper[j],color)
			end
		end
		-- Invisible trail attachment support follows the authored blade silhouette.
		local blade=piece("Blade",Vector3.new(.05,2.4,.05),CFrame.new(0,1.48,0),steel); blade.Transparency=1
		for _,side in {-1,1} do bar("BladeInlay",Vector3.new(side*.06,.25,-.09),Vector3.new(side*.035,.78,-.103),.024,bronze) end
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
		spindle("MaceGrip",1.6,.17,CFrame.new(0,-.35,0),leather)
		for i=0,8 do spindle("GripWrap",.035,.19,CFrame.new(0,-1.03+i*.16),wood) end
		for _,y in {-1.15,.47} do
			spindle("GripCap",.13,.24,CFrame.new(0,y,0),bronze)
			ball("CapRivet",Vector3.one*.16,Vector3.new(0,y,-.23),edge)
		end
		for i=1,5 do
			local cf=CFrame.new(0,.5+i*.23,0)*CFrame.Angles(0,if i%2==0 then math.pi/2 else 0,0)
			for j=0,7 do
				local a=j/8*math.pi*2; local b=(j+1)/8*math.pi*2
				bar("ChainLink",cf:PointToWorldSpace(Vector3.new(math.cos(a)*.115,math.sin(a)*.17,0)),cf:PointToWorldSpace(Vector3.new(math.cos(b)*.115,math.sin(b)*.17,0)),.055,steel)
			end
		end
		maceHead(Vector3.new(0,2.20,0))
	elseif id=="MaceHead" then
		maceHead(Vector3.zero)
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
