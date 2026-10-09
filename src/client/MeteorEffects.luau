--!nonstrict
local RunService=game:GetService("RunService")
local Debris=game:GetService("Debris")
local TweenService=game:GetService("TweenService")
local Config=require(game:GetService("ReplicatedStorage").Shared.Config)
local Effects={}
function Effects.new()
	local folder=Instance.new("Folder"); folder.Name="MeteorEffects"; folder.Parent=workspace
	local warnings={}; local falling={}
	local function part(parent,size,color,material)
		local p=Instance.new("Part"); p.Size=size; p.Color=color; p.Material=material or Enum.Material.Rock
		p.Anchored=true; p.CanCollide=false; p.CanQuery=false; p.CanTouch=false; p.Parent=parent; return p
	end
	local function target(data)
		if data.part and data.part.Parent then return data.part.CFrame:PointToWorldSpace(data.localPoint) end
		return data.target
	end
	local function alive(data)
		return data.part and data.part.Parent and not data.part.Parent:GetAttribute("Broken")
	end
	local function clear()
		table.clear(warnings); table.clear(falling); folder:ClearAllChildren()
	end
	workspace:GetAttributeChangedSignal("Phase"):Connect(function()
		if workspace:GetAttribute("Phase")~="Live" then clear() end
	end)
	RunService.RenderStepped:Connect(function()
		local now=workspace:GetServerTimeNow()
		for i=#warnings,1,-1 do
			local data=warnings[i]
			if now>=data.endsAt or not alive(data) then data.model:Destroy(); table.remove(warnings,i); continue end
			local cf=data.part.CFrame*CFrame.new(data.localPoint)
			local heat=math.clamp(1-(data.endsAt-now)/(Config.Hazards.MeteorLeadTime+Config.Hazards.MeteorFallTime),0,1)
			for j,p in data.parts do
				local angle=(j-1)/#data.parts*math.pi*2
				p.CFrame=cf*CFrame.new(math.sin(angle)*data.radius,.07,math.cos(angle)*data.radius)*CFrame.Angles(0,angle+math.pi/2,0)
				p.Color=Color3.fromRGB(250,169,58):Lerp(Color3.fromRGB(255,55,27),heat)
			end
		end
		for i=#falling,1,-1 do
			local data=falling[i]
			if now>=data.endsAt or not data.model.Parent or not alive(data) then
				data.model:Destroy(); table.remove(falling,i); continue
			end
			local u=math.clamp(1-(data.endsAt-now)/Config.Hazards.MeteorFallTime,0,1)
			local position=data.from:Lerp(target(data),u*u)
			data.model:PivotTo(CFrame.new(position)*CFrame.Angles(u*2,u*3,u))
		end
	end)
	return function(kind,a,b)
		if kind=="MeteorTelegraph" then
			local model=Instance.new("Model"); model.Name="ImpactWarning"; model.Parent=folder
			local data=table.clone(b); data.model=model; data.parts={}
			for _=1,28 do
				local p=part(model,Vector3.new(.28,.065,b.radius*math.pi*2/28*.85),Color3.fromRGB(250,169,58),Enum.Material.Neon)
				p.CastShadow=false; table.insert(data.parts,p)
			end
			table.insert(warnings,data); return true
		elseif kind=="MeteorIncoming" then
			local model=Instance.new("Model"); model.Name="Meteor"; model.Parent=folder
			local size=Config.Hazards.MeteorSize
			local rock=part(model,Vector3.new(size,size*.90,size*.95),Color3.fromRGB(73,49,36))
			rock.Shape=Enum.PartType.Ball; rock.CFrame=CFrame.new(a); model.PrimaryPart=rock
			for i=1,4 do
				local chip=part(model,Vector3.new(size*.5,size*.55,size*.5),Color3.fromRGB(93+i*3,57,34))
				chip.CFrame=rock.CFrame*CFrame.new(math.cos(i*2.1)*size*.31,math.sin(i*2.1)*size*.28,size*.15)*CFrame.Angles(i,.5*i,0)
				local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.Wedge; mesh.Parent=chip
			end
			local fire=Instance.new("Fire"); fire.Size=size*1.4; fire.Heat=8
			fire.Color=Color3.fromRGB(255,156,53); fire.SecondaryColor=Color3.fromRGB(137,41,16); fire.Parent=rock
			local light=Instance.new("PointLight"); light.Color=fire.Color; light.Brightness=2; light.Range=28; light.Parent=rock
			local data=table.clone(b); data.model=model; data.from=a; table.insert(falling,data)
			return true
		elseif kind=="MeteorImpact" then
			for i=1,9 do
				local angle=i/9*math.pi*2
				local debris=part(folder,Vector3.new(.8+i%3*.3,.6,1.1),Color3.fromRGB(97,77,56))
				debris.CFrame=CFrame.new(a)*CFrame.Angles(i,i*.7,0)
				local offset=Vector3.new(math.sin(angle)*(6+i*.5),3+i%3,math.cos(angle)*(6+i*.5))
				TweenService:Create(debris,TweenInfo.new(.55,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=debris.CFrame+offset,Transparency=1}):Play()
				Debris:AddItem(debris,.6)
			end
			return false -- also use the shared dust impact
		end
		return false
	end
end
return Effects
