--!nonstrict
local U=require(script.Parent.Util)
local G=require(script.Parent.Geometry)
local Visuals={}
local bronze=Color3.fromRGB(157,121,65)
local iron=Color3.fromRGB(87,90,87)
local wood=Color3.fromRGB(111,74,43)
function Visuals.attach(root,id)
	local function finish(part)
		part.Massless=true; part.CanCollide=false; part.CanQuery=false; part.CanTouch=false
		U.weld(root,part); return part
	end
	local function piece(name,size,offset,color,material)
		return finish(U.part(root,name,size,root.CFrame*offset,color,material))
	end
	if id=="Shield" then
		finish(G.cylinder(root,"BronzeShield",1.18,.22,root.CFrame*CFrame.Angles(math.pi/2,0,0),bronze,Enum.Material.Metal))
		local boss=piece("ShieldBoss",Vector3.one*.6,CFrame.new(0,0,-.2),iron,Enum.Material.Metal); boss.Shape=Enum.PartType.Ball
	elseif id=="Sword" then
		piece("SwordGrip",Vector3.new(.28,.8,.28),CFrame.new(0,-.65,0),wood,Enum.Material.Wood)
		piece("SwordGuard",Vector3.new(1.15,.16,.25),CFrame.new(0,-.2,0),bronze,Enum.Material.Metal)
		local blade=piece("SwordBlade",Vector3.new(.24,2.5,.16),CFrame.new(0,1.1,0),Color3.fromRGB(202,202,196),Enum.Material.Metal)
		blade.Reflectance=.08
	elseif id=="Mace" then
		piece("MaceHandle",Vector3.new(.32,1.9,.32),CFrame.new(0,-.25,0),wood,Enum.Material.Wood)
		piece("MaceCollar",Vector3.new(.7,.22,.7),CFrame.new(0,.65,0),bronze,Enum.Material.Metal)
		local head=piece("MaceHead",Vector3.new(1.25,1.25,1.25),CFrame.new(0,1.35,0),iron,Enum.Material.Metal)
		head.Shape=Enum.PartType.Ball
	elseif id=="Bow" then
		local previous=nil
		for i=0,8 do
			local a=-math.pi/2+i/8*math.pi; local point=(root.CFrame*CFrame.new(math.cos(a)*.7-.3,math.sin(a)*1.4,0)).Position
			if previous then finish(G.line(root,"BowLimb",previous,point,.16,wood,Enum.Material.Wood)) end
			previous=point
		end
		piece("BowString",Vector3.new(.035,2.8,.035),CFrame.new(-.3,0,0),Color3.fromRGB(204,188,157),Enum.Material.Fabric)
	elseif id=="Anchor" then
		piece("AnchorStem",Vector3.new(.3,2.2,.3),CFrame.identity,iron,Enum.Material.Metal)
		piece("AnchorCrossbar",Vector3.new(1.8,.25,.3),CFrame.new(0,.4,0),bronze,Enum.Material.Metal)
		for _,side in {-1,1} do
			piece("AnchorFluke",Vector3.new(1.2,.3,.35),CFrame.new(side*.45,-.7,0)*CFrame.Angles(0,0,side*.5),iron,Enum.Material.Metal)
		end
	elseif id=="Ram" then
		piece("RamHandle",Vector3.new(.4,2.2,.4),CFrame.new(0,-.25,0),wood,Enum.Material.Wood)
		piece("RamHead",Vector3.new(2.1,.85,.9),CFrame.new(0,.8,0),bronze,Enum.Material.Metal)
	elseif id=="Brace" then
		for _,side in {-1,1} do piece("BraceTimber",Vector3.new(.55,2.3,.5),CFrame.Angles(0,0,side*.4),wood,Enum.Material.Wood) end
		piece("BraceBand",Vector3.new(1.7,.35,.62),CFrame.identity,iron,Enum.Material.Metal)
	else
		piece("StoneWeight",Vector3.new(1.7,1.6,1.6),CFrame.identity,iron,Enum.Material.Slate)
		piece("WeightBand",Vector3.new(1.76,.3,1.66),CFrame.identity,bronze,Enum.Material.Metal)
	end
end
return Visuals
