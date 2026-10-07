--!nonstrict
local Lighting=game:GetService("Lighting")
local U=require(script.Parent.Util)
local G=require(script.Parent.Geometry)
local Coliseum={}
local stone=Color3.fromRGB(184,166,137)
local pale=Color3.fromRGB(205,189,160)
local shadow=Color3.fromRGB(108,98,84)
local bronze=Color3.fromRGB(137,106,60)
local red=Color3.fromRGB(100,36,31)
local material=Enum.Material.Limestone

local function model(parent,name)
	local m=Instance.new("Model"); m.Name=name; m.Parent=parent; return m
end
local function sign(part,face,title,subtitle)
	local gui=Instance.new("SurfaceGui"); gui.Face=face; gui.CanvasSize=Vector2.new(700,300)
	gui.LightInfluence=.65; gui.PixelsPerStud=30; gui.Parent=part
	local text=Instance.new("TextLabel"); text.BackgroundTransparency=1; text.Size=UDim2.fromScale(.94,.6)
	text.Position=UDim2.fromScale(.03,.1); text.Font=Enum.Font.GothamBold; text.TextSize=57
	text.TextColor3=Color3.fromRGB(238,224,194); text.TextWrapped=true; text.Text=title; text.Parent=gui
	local small=text:Clone(); small.Size=UDim2.fromScale(.94,.24); small.Position=UDim2.fromScale(.03,.7)
	small.TextSize=27; small.Text=subtitle; small.Font=Enum.Font.Gotham; small.Parent=gui
	return text,small
end
local function torch(parent,cf)
	local holder=U.part(parent,"BrazierPlinth",Vector3.new(2.4,4,2.4),cf,shadow,material)
	local bowl=G.cylinder(parent,"BronzeBrazier",1.6,.7,cf*CFrame.new(0,2.3,0),bronze,Enum.Material.Metal)
	local fire=Instance.new("Fire"); fire.Size=3; fire.Heat=2; fire.Color=Color3.fromRGB(255,185,90)
	fire.SecondaryColor=Color3.fromRGB(143,54,17); fire.Parent=bowl
	local light=Instance.new("PointLight"); light.Color=Color3.fromRGB(255,183,105)
	light.Range=18; light.Brightness=1.1; light.Shadows=false; light.Parent=bowl
	holder.CanTouch=false
end
local function arch(parent,cf,width,height,depth,color)
	local radius=width*.34; local spring=height-radius-1.4; local pier=(width-radius*2)/2
	for _,side in {-1,1} do
		U.part(parent,"ArcadePier",Vector3.new(pier,spring,depth),cf*CFrame.new(side*(radius+pier/2),spring/2,0),color,material)
		local column=G.cylinder(parent,"EngagedColumn",.85,spring,cf*CFrame.new(side*(radius+pier*.6),spring/2,-depth*.52),pale,material)
		column.CanCollide=false
		U.part(parent,"ColumnCapital",Vector3.new(2.8,.8,2),cf*CFrame.new(side*(radius+pier*.6),spring-.2,-depth*.55),pale,material).CanCollide=false
	end
	for j=0,8 do
		local a=(j+.5)/9*math.pi
		local cf2=cf*CFrame.new(math.cos(a)*radius,spring+math.sin(a)*radius,0)*CFrame.Angles(0,0,a-math.pi/2)
		local block=U.part(parent,"ArchVoussoir",Vector3.new(math.pi*radius/9+.16,1.8,depth),cf2,color,material)
		block.CanCollide=false
	end
	U.part(parent,"Entablature",Vector3.new(width+.3,1.6,depth+.8),cf*CFrame.new(0,height-.3,0),pale,material)
end
local function statue(parent,cf)
	local plinth=U.part(parent,"StatueBase",Vector3.new(6,3,6),cf,shadow,material)
	U.part(parent,"StatueTorso",Vector3.new(3.6,5,2),cf*CFrame.new(0,5.5,0),pale,Enum.Material.Marble)
	local head=U.part(parent,"StatueHead",Vector3.new(2.3,2.8,2.3),cf*CFrame.new(0,9.3,0),pale,Enum.Material.Marble); head.Shape=Enum.PartType.Ball
	for _,x in {-1,1} do
		U.part(parent,"StatueLeg",Vector3.new(1.3,4,1.5),cf*CFrame.new(x,2.5,0),pale,Enum.Material.Marble)
		U.part(parent,"StatueArm",Vector3.new(1.2,4,1.4),cf*CFrame.new(x*2.3,5.8,0)*CFrame.Angles(0,0,-x*.12),pale,Enum.Material.Marble)
	end
	local shield=G.cylinder(parent,"StatueShield",2.4,.4,cf*CFrame.new(-2.6,4.5,-1.2)*CFrame.Angles(math.pi/2,0,0),bronze,Enum.Material.Metal)
	shield.CanCollide=false; plinth.CanTouch=false
end
function Coliseum.light()
	Lighting.ClockTime=16.25; Lighting.Brightness=2.2; Lighting.ExposureCompensation=.05
	Lighting.GlobalShadows=true; Lighting.ShadowSoftness=.3
	Lighting.Ambient=Color3.fromRGB(75,72,69); Lighting.OutdoorAmbient=Color3.fromRGB(118,111,99)
	Lighting.EnvironmentDiffuseScale=.65; Lighting.EnvironmentSpecularScale=.4
	for _,name in {"ArenaAtmosphere","ArenaGrade","ArenaBloom","ArenaSun"} do
		local old=Lighting:FindFirstChild(name); if old then old:Destroy() end
	end
	local atmosphere=Instance.new("Atmosphere"); atmosphere.Name="ArenaAtmosphere"; atmosphere.Density=.22
	atmosphere.Offset=.12; atmosphere.Haze=2.05; atmosphere.Glare=.16
	atmosphere.Color=Color3.fromRGB(216,199,165); atmosphere.Decay=Color3.fromRGB(119,105,87); atmosphere.Parent=Lighting
	local grade=Instance.new("ColorCorrectionEffect"); grade.Name="ArenaGrade"; grade.Contrast=.09
	grade.Saturation=-.14; grade.TintColor=Color3.fromRGB(255,245,227); grade.Parent=Lighting
	local bloom=Instance.new("BloomEffect"); bloom.Name="ArenaBloom"; bloom.Intensity=.08; bloom.Size=20; bloom.Threshold=1.6; bloom.Parent=Lighting
	local sun=Instance.new("SunRaysEffect"); sun.Name="ArenaSun"; sun.Intensity=.025; sun.Spread=.6; sun.Parent=Lighting
end
function Coliseum.build(world)
	Coliseum.light()
	local building=model(world,"ColiseumArchitecture")
	local tiers=model(building,"AccessibleSpectatorTiers")
	-- Three continuous concourses. The seating risers between them are walkable.
	for i,spec in {{154,22,130},{202,12,151},{246,12,174}} do
		G.ring(tiers,"Concourse"..i,spec[1],spec[2],spec[3]-1.5,3,stone,material,80,.96)
		-- Only the innermost edge needs a continuous guard, to preserve stair access.
		if i == 1 then
			G.ring(tiers,"PitBalustrade",142,.9,132,4,pale,material,96,.97)
			G.ring(tiers,"BalustradeCap",142,1.7,134.2,.45,bronze,material,96,.97)
		end
	end
	for section=1,2 do
		for row=0,17 do
			local radius=if section == 1 then 158+row*2.35 else 207+row*2.15
			local y=if section == 1 then 133+row*1.55 else 154+row*1.6
			local pieces=G.ring(tiers,"SeatingTier",radius,if section == 1 then 2.2 else 1.7,y-.75,1.5,pale,material,64,.96)
			for index,part in pieces do
				-- Leave a monumental, open entrance above the lower lobby courtyard.
				local p=part.Position
				if p.Z < -150 and math.abs(p.X)<50 then part:Destroy()
				elseif (index-1)%16 == 0 then part.Name="RadialStair"; part.Color=stone
				else part.Color=pale:Lerp(stone,(row%3)*.08) end
			end
		end
	end
	-- A continuous outer arcade, with actual openings rather than painted arches.
	local bays=56; local radius=276
	for level=0,2 do
		local baseY=125+level*24
		for i=0,bays-1 do
			local a=i/bays*2*math.pi
			local position=Vector3.new(math.sin(a)*radius,baseY,math.cos(a)*radius*.96)
			local cf=CFrame.new(position)*CFrame.Angles(0,a,0)
			local color=stone:Lerp(pale,((i*7+level)%5)*.055)
			arch(building,cf,2*radius*math.tan(math.pi/bays),21,4,color)
		end
		G.ring(building,"Cornice",radius,5.4,baseY+21,1.1,pale,material,80,.96)
	end
	G.ring(building,"AtticWall",276,4,198,10,stone,material,112,.97)
	G.ring(building,"Crown",276,6,204,1.5,pale,material,112,.97)
	G.ring(building,"Foundation",276,10,102,34,shadow,material,112,.97)
	G.ring(building,"OuterParapet",268,1,178,4,pale,material,112,.97)

	-- Distant seating fades into the atmosphere so the arena feels far larger than the playable shell.
	for row=0,20 do
		local radius=292+row*7.5
		local y=198+row*2.3
		local fade=math.clamp(row/20,0,1)
		local c=pale:Lerp(Color3.fromRGB(199,190,176),fade*.55)
		for _,part in G.ring(building,"DistantTier",radius,6.6,y,2.2,c,material,96,.98) do
			part.Transparency=.08+fade*.58
			part.CanCollide=false
			part.CanQuery=false
			part.CastShadow=row<7
		end
	end
	-- Banners, bronze brackets and limited warm lights set the visual rhythm.
	for i=0,11 do
		local a=i/12*math.pi*2; local cf=CFrame.new(math.sin(a)*270,184,math.cos(a)*270*.97)*CFrame.Angles(0,a,0)
		local banner=U.part(building,"ClothBanner",Vector3.new(6.5,15,.18),cf,red,Enum.Material.Fabric)
		banner.CanCollide=false; banner.CanQuery=false
		U.part(building,"BannerHem",Vector3.new(6.5,.25,.22),cf*CFrame.new(0,-7,0),bronze,Enum.Material.Fabric).CanCollide=false
		G.line(building,"BannerRod",(cf*CFrame.new(-4,8,0)).Position,(cf*CFrame.new(4,8,0)).Position,.2,bronze,Enum.Material.Metal)
		if i%2 == 0 and i~=6 then torch(building,CFrame.new(math.sin(a)*151,132,math.cos(a)*151*.97)) end
	end
	-- Dark depth, a masonry support drum, and strata inside the chasm.
	G.ring(building,"ChasmWall",140,12,64,112,Color3.fromRGB(50,48,46),Enum.Material.Rock,96,1)
	local drum=G.cylinder(building,"SupportDrum",11.5,104,CFrame.new(0,68,0),Color3.fromRGB(55,53,52),Enum.Material.Slate)
	local capital=G.cylinder(building,"SupportCapital",15,4,CFrame.new(0,120,0),bronze,material)
	drum.CanCollide=false; drum.CanQuery=false; capital.CanCollide=false; capital.CanQuery=false
	local pit=G.cylinder(building,"Void",138,5,CFrame.new(0,11,0),Color3.fromRGB(4,5,7),Enum.Material.SmoothPlastic)
	pit.CanCollide=false; pit.CanQuery=false
	for i=0,4 do
		local ring=G.ring(building,"AbyssCourse",135-i*5,4,25+i*15,3,Color3.fromRGB(42+i*4,40+i*4,39+i*4),Enum.Material.Rock,80,1)
		for _,part in ring do part.Transparency=.16+i*.08; part.CanCollide=false; part.CanQuery=false end
	end
	local lobby=model(world,"LobbyCourtyard")
	U.part(lobby,"CourtyardFloor",Vector3.new(74,3,62),CFrame.new(0,128.5,-183),stone,material)
	for _,x in {-34,34} do
		U.part(lobby,"CourtyardInlay",Vector3.new(.3,.035,54),CFrame.new(x,130.02,-183),bronze,Enum.Material.Metal).CanCollide=false
		statue(lobby,CFrame.new(x,131.5,-203)); torch(lobby,CFrame.new(x,132,-158))
	end
	local spawn=Instance.new("SpawnLocation"); spawn.Name="LobbySpawn"; spawn.Size=Vector3.new(5,.2,5)
	spawn.CFrame=CFrame.new(0,130.1,-214); spawn.Transparency=1; spawn.Anchored=true; spawn.CanCollide=false
	spawn.Duration=0; spawn.Neutral=true; spawn.Parent=lobby
	local inscription=U.part(lobby,"ArenaInscription",Vector3.new(40,4,.8),CFrame.new(0,141,-225),shadow,material)
	sign(inscription,Enum.NormalId.Back,"ROMAN COLISEUM","PUSH  /  BALANCE  /  SURVIVE")
	local pads={}
	local function pad(kind,index,name,sub,x,z,width,depth)
		local base=U.part(lobby,"SelectionPad",Vector3.new(width,.35,depth),CFrame.new(x,130.2,z),shadow,material)
		local edge=U.part(lobby,"SelectionBorder",Vector3.new(width+.5,.12,depth+.5),CFrame.new(x,130.01,z),bronze,Enum.Material.Metal)
		edge.CanCollide=false
		local title,small=sign(base,Enum.NormalId.Top,name,sub)
		table.insert(pads,{part=base,kind=kind,index=index,title=title,small=small,name=name,edge=edge})
	end
	pad("map",1,"ROMAN COLISEUM","STEP ON THE STONE TO SELECT",0,-165,32,13)
	for i,mode in {"FFA","Duos","Squads"} do
		pad("mode",i,if mode == "FFA" then "FREE FOR ALL" else string.upper(mode),"WAITING FOR MAP SELECTION",(i-2)*25,-192,21,11)
	end
	return {spawn=CFrame.lookAt(Vector3.new(0,134,-214),Vector3.new(0,134,0)),pads=pads,lobby=lobby}
end
return Coliseum
