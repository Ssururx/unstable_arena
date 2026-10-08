--!nonstrict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local CollectionService=game:GetService("CollectionService")
local Hotbar=require(script.Hotbar)
require(script.CombatAnimation).start()
local Config=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local player=Players.LocalPlayer
local remotes=ReplicatedStorage:WaitForChild("Remotes")
local action=remotes:WaitForChild("Action")
local fx=remotes:WaitForChild("FX")
local colors={bg=Color3.fromRGB(32,31,27),soft=Color3.fromRGB(62,58,49),text=Color3.fromRGB(242,231,210),gold=Color3.fromRGB(191,155,91)}
local gui=Instance.new("ScreenGui"); gui.Name="UnstableArenaUI"; gui.ResetOnSpawn=false
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.Parent=player:WaitForChild("PlayerGui")
local scales={}
local function roundCorner(object,radius)
	local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,radius or 10); corner.Parent=object
end
local function panel(name,size,pos,anchor)
	local f=Instance.new("Frame"); f.Name=name; f.Size=size; f.Position=pos; f.AnchorPoint=anchor
	f.BackgroundColor3=colors.bg; f.BackgroundTransparency=.12; f.BorderSizePixel=0; f.Parent=gui
	roundCorner(f)
	local scale=Instance.new("UIScale"); scale.Parent=f; table.insert(scales,scale)
	return f
end
local function label(parent,text,size,pos,textSize)
	local l=Instance.new("TextLabel"); l.BackgroundTransparency=1; l.Size=size; l.Position=pos
	l.Font=Enum.Font.GothamBold; l.TextColor3=colors.text; l.TextSize=textSize or 16
	l.Text=text; l.TextWrapped=true; l.Parent=parent; return l
end
local function button(parent,text,size,pos,callback)
	local b=Instance.new("TextButton"); b.Size=size; b.Position=pos; b.BackgroundColor3=colors.soft
	b.BorderSizePixel=0; b.Font=Enum.Font.GothamBold; b.TextSize=14; b.TextColor3=colors.text
	b.Text=text; b.Parent=parent; roundCorner(b,8); b.Activated:Connect(callback); return b
end
local top=panel("Round",UDim2.fromOffset(390,68),UDim2.fromScale(.5,.02),Vector2.new(.5,0))
top.BackgroundTransparency=.22
local title=label(top,"ROMAN COLISEUM",UDim2.new(1,-75,0,26),UDim2.fromOffset(12,6),18)
local subtitle=label(top,"",UDim2.new(1,-75,0,25),UDim2.fromOffset(12,34),12)
subtitle.TextXAlignment=Enum.TextXAlignment.Left
local timer=label(top,"",UDim2.fromOffset(58,42),UDim2.new(1,-66,0,12),28); timer.TextColor3=colors.gold
local stats=panel("SessionStats",UDim2.fromOffset(210,28),UDim2.fromScale(.02,.02),Vector2.zero)
local statText=label(stats,"0 wins • 0 coins",UDim2.fromScale(1,1),UDim2.new(),12)
local toastPanel=panel("Toast",UDim2.fromOffset(480,46),UDim2.fromScale(.5,.2),Vector2.new(.5,0))
toastPanel.Visible=false
local toastText=label(toastPanel,"",UDim2.new(1,-20,1,-8),UDim2.fromOffset(10,4),16)
local toastUntil=0
local function toast(message)
	toastText.Text=message; toastUntil=os.clock()+3; toastPanel.Visible=true
end
local cooldown={}
local following=nil; local firstPerson=false; local wantLock=false; local locked=false
local sprintToggle=false
local actionPanel=panel("Actions",UDim2.fromOffset(278,76),UDim2.fromScale(.98,.70),Vector2.new(1,1))
local actionButtons={}
local function send(kind)
	if following or GuiService.MenuIsOpen or UIS:GetFocusedTextBox() then return end
	if (cooldown[kind] or 0) > os.clock() then return end
	local camera=workspace.CurrentCamera; if not camera then return end
	local aim=camera.CFrame.LookVector
	if kind == "UseItem" then
		local center=camera.ViewportSize/2
		local ray=camera:ViewportPointToRay(center.X,center.Y)
		local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then aim=(ray.Origin+ray.Direction*200-(root.Position+Vector3.new(0,1,0))).Unit end
	end
	action:FireServer(kind,aim)
end
actionButtons.Push=button(actionPanel,"PUSH\nE / Click",UDim2.fromOffset(88,62),UDim2.fromOffset(6,7),function() send("Push") end)
actionButtons.Grab=button(actionPanel,"GRAB\nQ",UDim2.fromOffset(80,62),UDim2.fromOffset(99,7),function() send("Grab") end)
actionButtons.UseItem=button(actionPanel,"ITEM\nF",UDim2.fromOffset(88,62),UDim2.fromOffset(184,7),function() send("UseItem") end)
for _,b in actionButtons do b.TextWrapped=true end
local mobility=panel("Mobility",UDim2.fromOffset(278,55),UDim2.fromScale(.98,.54),Vector2.new(1,1))
mobility.BackgroundTransparency=1
button(mobility,"DASH",UDim2.fromOffset(86,48),UDim2.new(),function() send("Dash") end)
button(mobility,"SLIDE",UDim2.fromOffset(86,48),UDim2.fromOffset(94,0),function() send("Slide") end)
button(mobility,"SPRINT",UDim2.fromOffset(86,48),UDim2.fromOffset(188,0),function()
	sprintToggle=not sprintToggle; action:FireServer("Sprint",sprintToggle)
end)
local inventory=panel("Inventory",UDim2.fromOffset(224,68),UDim2.new(.5,0,1,-18),Vector2.new(.5,1))
inventory.BackgroundTransparency=1
local itemHint=label(inventory,"",UDim2.fromOffset(380,20),UDim2.fromOffset(-78,-26),11)
itemHint.TextColor3=Color3.fromRGB(222,210,185)
local slotButtons=Hotbar.build(inventory,function(slot)
	if not following and not GuiService.MenuIsOpen then action:FireServer("SelectSlot",slot) end
end)
local adrenaline=panel("Adrenaline",UDim2.fromOffset(224,5),UDim2.new(.5,0,1,-122),Vector2.new(.5,1))
adrenaline.BackgroundTransparency=.4
local adrenalineTrack=Instance.new("Frame"); adrenalineTrack.Size=UDim2.fromScale(1,1)
adrenalineTrack.BackgroundColor3=Color3.fromRGB(45,43,39); adrenalineTrack.BorderSizePixel=0; adrenalineTrack.Parent=adrenaline; roundCorner(adrenalineTrack,3)
local adrenalineFill=Instance.new("Frame"); adrenalineFill.Size=UDim2.fromScale(0,1); adrenalineFill.BackgroundColor3=Color3.fromRGB(202,118,58)
adrenalineFill.BorderSizePixel=0; adrenalineFill.Parent=adrenalineTrack; roundCorner(adrenalineFill,3)
local adrenalineText=label(adrenalineTrack,"",UDim2.new(1,0,0,18),UDim2.fromOffset(0,-21),10)
local rushButton=Instance.new("TextButton"); rushButton.Size=UDim2.new(1,0,0,30)
rushButton.Position=UDim2.fromOffset(0,-25); rushButton.BackgroundTransparency=1; rushButton.Text=""
rushButton.Parent=adrenaline; rushButton.Activated:Connect(function() send("Adrenaline") end)
local hazardPanel=panel("Hazard",UDim2.fromOffset(420,32),UDim2.fromScale(.5,.115),Vector2.new(.5,0))
hazardPanel.Visible=false; hazardPanel.BackgroundTransparency=.16
local hazardText=label(hazardPanel,"",UDim2.new(1,-12,1,0),UDim2.fromOffset(6,0),13)
local crosshair=label(gui,"+",UDim2.fromOffset(24,24),UDim2.new(.5,-12,.5,-12),24)
crosshair.TextTransparency=.15
local lockPanel=panel("Lock",UDim2.fromOffset(190,32),UDim2.fromScale(.02,.97),Vector2.new(0,1))
local lockButton=button(lockPanel,"RSHIFT LOCK: OFF",UDim2.fromScale(1,1),UDim2.new(),function() wantLock=not wantLock end)
lockPanel.BackgroundTransparency=1; lockButton.BackgroundTransparency=.35
local controlHint=label(gui,"E PUSH  •  Q GRAB  •  F USE  •  SHIFT SPRINT  •  X DASH  •  C SLIDE  •  G RUSH",UDim2.fromOffset(650,22),UDim2.new(.5,-325,1,-167),11)
local spec=panel("Spectator",UDim2.fromOffset(450,88),UDim2.fromScale(.5,.82),Vector2.new(.5,1))
local specTitle=label(spec,"WATCH FROM THE STANDS",UDim2.new(1,-12,0,26),UDim2.fromOffset(6,3),14)
local function character(actor) return if actor:IsA("Player") then actor.Character else actor end
local function actorName(actor) return if actor:IsA("Player") then actor.DisplayName else actor:GetAttribute("DisplayName") or actor.Name end
local function subjects()
	local list={}
	for _,p in Players:GetPlayers() do
		if p ~= player and p:GetAttribute("InRound") and p.Character and p.Character:FindFirstChildOfClass("Humanoid") then table.insert(list,p) end
	end
	for _,bot in CollectionService:GetTagged("ArenaBot") do
		if bot:GetAttribute("InRound") and bot:FindFirstChildOfClass("Humanoid") then table.insert(list,bot) end
	end
	local function id(a) return if a:IsA("Player") then a.UserId else a:GetAttribute("ActorId") or 0 end
	table.sort(list,function(a,b) return id(a)<id(b) end)
	return list
end
local function restoreCamera()
	following=nil; firstPerson=false
	local camera=workspace.CurrentCamera
	local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if camera then camera.CameraType=Enum.CameraType.Custom; if hum then camera.CameraSubject=hum end end
end
local function cycle(direction)
	local list=subjects(); if #list == 0 then restoreCamera(); toast("Nobody to spectate yet"); return end
	local index=table.find(list,following) or (if direction > 0 then 0 else 1)
	following=list[((index-1+direction)%#list)+1]
end
button(spec,"STANDS",UDim2.fromOffset(100,38),UDim2.fromOffset(8,40),restoreCamera)
button(spec,"‹",UDim2.fromOffset(45,38),UDim2.fromOffset(115,40),function() cycle(-1) end)
button(spec,"SPECTATE ›",UDim2.fromOffset(135,38),UDim2.fromOffset(167,40),function() cycle(1) end)
local povButton=button(spec,"POV: THIRD",UDim2.fromOffset(133,38),UDim2.fromOffset(309,40),function()
	if not following then cycle(1) end
	firstPerson=not firstPerson
end)
UIS.InputBegan:Connect(function(input,processed)
	if processed or UIS:GetFocusedTextBox() then return end
	local key=input.KeyCode
	if key == Enum.KeyCode.LeftShift then action:FireServer("Sprint",true)
	elseif key == Enum.KeyCode.RightShift then wantLock=not wantLock
	elseif key == Enum.KeyCode.One then action:FireServer("SelectSlot",1)
	elseif key == Enum.KeyCode.Two then action:FireServer("SelectSlot",2)
	elseif key == Enum.KeyCode.Three then action:FireServer("SelectSlot",3)
	elseif key==Enum.KeyCode.ButtonR1 or key==Enum.KeyCode.ButtonL1 then
		local delta=if key==Enum.KeyCode.ButtonR1 then 1 else -1
		action:FireServer("SelectSlot",((player:GetAttribute("ActiveSlot") or 1)-1+delta)%3+1)
	elseif key==Enum.KeyCode.ButtonL3 then sprintToggle=not sprintToggle; action:FireServer("Sprint",sprintToggle)
	elseif key==Enum.KeyCode.DPadDown then send("Adrenaline")
	elseif key==Enum.KeyCode.ButtonR3 then send("Slide")
	elseif key == Enum.KeyCode.X or key == Enum.KeyCode.ButtonB then send("Dash")
	elseif key == Enum.KeyCode.C then send("Slide")
	elseif key == Enum.KeyCode.G then send("Adrenaline")
	elseif key == Enum.KeyCode.E or key == Enum.KeyCode.ButtonR2 or input.UserInputType == Enum.UserInputType.MouseButton1 then send("Push")
	elseif key == Enum.KeyCode.Q or key == Enum.KeyCode.ButtonX then send("Grab")
	elseif key == Enum.KeyCode.F or key == Enum.KeyCode.ButtonL2 then send("UseItem")
	end
end)
UIS.WindowFocusReleased:Connect(function() action:FireServer("Sprint",false) end)
GuiService.MenuOpened:Connect(function() action:FireServer("Sprint",false) end)
UIS.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift then action:FireServer("Sprint",false) end
end)
player.CharacterAdded:Connect(function() restoreCamera(); wantLock=false; action:FireServer("Sprint",false) end)
local effects=Instance.new("Folder"); effects.Name="ArenaLocalEffects"; effects.Parent=workspace
local rangeSegments={}
for i=1,48 do
	local p=Instance.new("Part"); p.Name="MaceRangeEdge"; p.Anchored=true
	p.CanCollide=false; p.CanQuery=false; p.CanTouch=false; p.CastShadow=false
	p.Material=Enum.Material.Neon; p.Color=colors.gold; p.Transparency=1; p.Parent=effects
	rangeSegments[i]=p
end
local rangeAt=0
local function updateRange(root,visible)
	if not visible then for _,p in rangeSegments do p.Transparency=1 end; return end
	if os.clock()<rangeAt then return end
	rangeAt=os.clock()+.05
	local world=workspace:FindFirstChild("UnstableArenaWorld")
	local arena=world and world:FindFirstChild("RoundArena")
	if not arena then return end
	local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Include; params.FilterDescendantsInstances={arena}
	local radius=Config.Combat.MaceLockRange
	for i,p in rangeSegments do
		local angle=(i-1)/#rangeSegments*math.pi*2
		local offset=Vector3.new(math.sin(angle),0,math.cos(angle))*radius
		local hit=workspace:Raycast(root.Position+offset+Vector3.new(0,35,0),Vector3.new(0,-75,0),params)
		if hit and not hit.Instance.Parent:GetAttribute("Broken") then
			p.Size=Vector3.new(.12,.04,radius*math.pi*2/#rangeSegments*.74)
			local tangent=Vector3.new(math.cos(angle),0,-math.sin(angle))
			tangent=(tangent-hit.Normal*tangent:Dot(hit.Normal)).Unit
			p.CFrame=CFrame.lookAt(hit.Position+hit.Normal*.12,hit.Position+hit.Normal*.12+tangent,hit.Normal)
			p.Transparency=.30
		else p.Transparency=1 end
	end
end
local flyingMaces={}
local hitUntil=0
local function effect(kind,a,b)
	local camera=workspace.CurrentCamera
	if typeof(a)~="Vector3" or not camera or (camera.CFrame.Position-a).Magnitude>420 or #effects:GetChildren()>=120 then return end

	local function basePart()
		local p=Instance.new("Part")
		p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false
		p.Material=Enum.Material.SmoothPlastic; p.Color=colors.gold; p.Transparency=.3
		p.Parent=effects
		return p
	end
	local function line(from,to,width,color,duration)
		if typeof(to)~="Vector3" or (to-from).Magnitude<.01 then return end
		local p=basePart(); p.Size=Vector3.new(width,width,(to-from).Magnitude)
		p.CFrame=CFrame.lookAt((from+to)/2,to); p.Color=color; p.Material=Enum.Material.Neon
		TweenService:Create(p,TweenInfo.new(duration or .22),{Transparency=1}):Play()
		Debris:AddItem(p,(duration or .22)+.05)
	end
	local function burst(position,color,count,size)
		local p=basePart(); p.Size=Vector3.one*.1; p.Position=position; p.Transparency=1
		local emitter=Instance.new("ParticleEmitter")
		emitter.Texture="rbxasset://textures/particles/smoke_main.dds"
		emitter.Color=ColorSequence.new(color)
		emitter.Lifetime=NumberRange.new(.25,.7); emitter.Speed=NumberRange.new(3,11)
		emitter.SpreadAngle=Vector2.new(180,180); emitter.Rate=0; emitter.LightInfluence=.65
		emitter.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.3),NumberSequenceKeypoint.new(1,size or 2)})
		emitter.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.2),NumberSequenceKeypoint.new(1,1)})
		emitter.Parent=p; emitter:Emit(count or 8); Debris:AddItem(p,.9)
	end

	if kind=="DangerCircle" or kind=="MaceWarning" then
		local radius=if kind=="MaceWarning" then 4 else (if typeof(b)=="number" then b else 12)
		local duration=if kind=="MaceWarning" then b else (Config.Hazards.MeteorTelegraphTime+Config.Hazards.MeteorFallTime)
		local world=workspace:FindFirstChild("UnstableArenaWorld")
		local arena=world and world:FindFirstChild("RoundArena"); if not arena then return end
		local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Include; params.FilterDescendantsInstances={arena}
		local marker=Instance.new("Model"); marker.Name="WarningRing"; marker.Parent=effects
		for i=0,23 do
			local angle=i/24*math.pi*2
			local point=a+Vector3.new(math.sin(angle)*radius,18,math.cos(angle)*radius)
			local hit=workspace:Raycast(point,Vector3.new(0,-45,0),params)
			if hit then
				local ring=basePart(); ring.Parent=marker; ring.Material=Enum.Material.Neon
				ring.Color=Color3.fromRGB(240,134,65); ring.Transparency=.15
				ring.Size=Vector3.new(.23,.06,radius*math.pi*2/24*.8)
				local tangent=Vector3.new(math.cos(angle),0,-math.sin(angle))
				tangent=(tangent-hit.Normal*tangent:Dot(hit.Normal)).Unit
				ring.CFrame=CFrame.lookAt(hit.Position+hit.Normal*.15,hit.Position+hit.Normal*.15+tangent,hit.Normal)
				TweenService:Create(ring,TweenInfo.new(duration),{Color=Color3.fromRGB(255,63,40)}):Play()
			end
		end
		Debris:AddItem(marker,duration); return
	elseif kind=="MeteorIncoming" and typeof(b)=="Vector3" then
		local rock=basePart(); rock.Shape=Enum.PartType.Ball
		rock.Size=Vector3.one*Config.Hazards.MeteorVisualSize
		rock.Material=Enum.Material.Rock; rock.Color=Color3.fromRGB(83,55,40); rock.Position=a
		local fire=Instance.new("Fire"); fire.Size=Config.Hazards.MeteorVisualSize*1.45; fire.Heat=7; fire.Parent=rock
		local light=Instance.new("PointLight"); light.Color=Color3.fromRGB(255,132,62)
		light.Range=Config.Hazards.MeteorVisualSize*5; light.Brightness=3.2; light.Parent=rock
		TweenService:Create(rock,TweenInfo.new(Config.Hazards.MeteorFallTime,Enum.EasingStyle.Linear),{Position=b}):Play()
		Debris:AddItem(rock,Config.Hazards.MeteorFallTime+.08); return
	elseif kind=="MeteorImpact" then
		burst(a,Color3.fromRGB(225,119,58),38,7); return
	elseif kind=="PlateImpact" then
		burst(a,Color3.fromRGB(171,143,99),18,3.2); return
	elseif kind=="Mace" and typeof(b)=="table" then
		local projectile=flyingMaces[b.id]
		if not projectile or not projectile.head.Parent then
			local model=Instance.new("Model"); model.Name="ThrownMace"; model.Parent=effects
			local head=basePart(); head.Parent=model; head.Name="IronHead"; head.Transparency=0
			head.Material=Enum.Material.Metal; head.Color=Color3.fromRGB(78,81,79)
			head.Shape=Enum.PartType.Ball; head.Size=Vector3.one*1.25; head.Position=a
			local source=basePart(); source.Parent=model; source.Transparency=1; source.Size=Vector3.one*.1
			local from=Instance.new("Attachment"); from.Parent=source
			local to=Instance.new("Attachment"); to.Parent=head
			local chain=Instance.new("Beam"); chain.Attachment0=from; chain.Attachment1=to
			chain.Width0=.10; chain.Width1=.10; chain.FaceCamera=true
			chain.Color=ColorSequence.new(Color3.fromRGB(138,128,100)); chain.Segments=10
			chain.CurveSize0=-1; chain.CurveSize1=1; chain.Parent=head
			projectile={model=model,head=head,source=source}; flyingMaces[b.id]=projectile
			Debris:AddItem(model,2)
			task.delay(2,function() if flyingMaces[b.id]==projectile then flyingMaces[b.id]=nil end end)
		end
		projectile.source.Position=b.source
		TweenService:Create(projectile.head,TweenInfo.new(.055,Enum.EasingStyle.Linear),{Position=b.position}):Play()
		return
	elseif kind=="MaceEnd" then
		local projectile=flyingMaces[b]
		if projectile then projectile.model:Destroy(); flyingMaces[b]=nil end
		return
	elseif kind=="MaceImpact" then
		burst(a,Color3.fromRGB(180,139,78),12,2.3); return
	elseif kind=="Arrow" then
		line(a,b,.12,Color3.fromRGB(217,195,141),.22); return
	elseif kind=="Grab" then
		line(a,b,.12,Color3.fromRGB(210,208,186),.24); return
	elseif kind=="SwordSwing" and typeof(b)=="Vector3" then
		local dir=b.Magnitude>.1 and b.Unit or Vector3.zAxis
		line(a+Vector3.new(0,1,0),a+Vector3.new(0,1,0)+dir*5,.32,Color3.fromRGB(224,219,199),.16); return
	elseif kind=="Dash" or kind=="Slide" then
		burst(a,Color3.fromRGB(169,151,119),if kind=="Dash" then 9 else 14,if kind=="Dash" then 1.3 else 1.8); return
	elseif kind=="Adrenaline" then
		burst(a,Color3.fromRGB(231,126,62),22,2.5); return
	elseif kind=="LionSpawn" then
		burst(a,Color3.fromRGB(188,137,73),18,2.8); return
	elseif kind=="LionAttack" then
		burst(a,Color3.fromRGB(151,82,52),11,2); return
	end

	local part=basePart()
	part.Size=Vector3.one*.1
	part.Position=if kind=="Swing" and typeof(b)=="Vector3" then a+b*3 else a
	part.Transparency=1
	local dust=Instance.new("ParticleEmitter")
	dust.Texture="rbxasset://textures/particles/smoke_main.dds"
	dust.Color=ColorSequence.new(if kind=="Block" then Color3.fromRGB(186,207,224) else Color3.fromRGB(153,137,109))
	dust.Lifetime=NumberRange.new(.25,.6); dust.Speed=NumberRange.new(2,if kind=="Break" then 12 else 6)
	dust.SpreadAngle=Vector2.new(180,180); dust.Rate=0; dust.LightInfluence=.85
	dust.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.35),NumberSequenceKeypoint.new(1,if kind=="Break" then 4 else 1.5)})
	dust.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.45),NumberSequenceKeypoint.new(1,1)})
	dust.Parent=part
	dust:Emit(if kind=="Break" then 18 elseif kind=="Crack" then 7 else 4)
	Debris:AddItem(part,.8)
end
fx.OnClientEvent:Connect(function(kind,a,b)
	if kind == "LobbyView" and typeof(a)=="CFrame" then
		local camera=workspace.CurrentCamera
		if camera and not player:GetAttribute("InRound") then
			restoreCamera()
			camera.CFrame=CFrame.lookAt(a.Position-a.LookVector*12+Vector3.new(0,5,0),a.Position+a.LookVector*18+Vector3.new(0,2,0))
		end
	elseif kind == "Toast" then toast(a)
	elseif kind == "Cooldown" then cooldown[a]=os.clock()+b
	elseif kind == "ConfirmHit" then hitUntil=os.clock()+.16
	elseif kind == "Pickup" then
		local slot=slotButtons[b]
		if slot then slot.stroke.Color=Color3.fromRGB(255,244,214); TweenService:Create(slot.stroke,TweenInfo.new(.5),{Color=colors.gold}):Play() end
	else effect(kind,a,b) end
end)
local voteHighlight=Instance.new("Highlight"); voteHighlight.Name="MyVote"; voteHighlight.FillTransparency=.88
voteHighlight.FillColor=colors.gold; voteHighlight.OutlineColor=colors.gold; voteHighlight.OutlineTransparency=.12
voteHighlight.DepthMode=Enum.HighlightDepthMode.Occluded; voteHighlight.Enabled=false; voteHighlight.Parent=workspace
local function updateUI()
	local camera=workspace.CurrentCamera; if not camera then return end
	local scale=math.min(1,camera.ViewportSize.X/620,camera.ViewportSize.Y/560)
	for _,s in scales do s.Scale=scale end
	if UIS.TouchEnabled then
		inventory:FindFirstChildOfClass("UIScale").Scale=math.max(.8,scale)
	end
	local phase=workspace:GetAttribute("Phase") or "Waiting"
	local active=player:GetAttribute("InRound") == true
	local voteKind=if phase=="MapVote" then "map" elseif phase=="ModeVote" then "mode" else nil
	local vote=voteKind and player:GetAttribute("Selected"..voteKind)
	voteHighlight.Enabled=false
	local world=workspace:FindFirstChild("UnstableArenaWorld")
	local lobby=world and world:FindFirstChild("LobbyCourtyard")
	local gallery=lobby and lobby:FindFirstChild("VotingGallery")
	if vote and gallery then
		for _,part in gallery:GetChildren() do
			if part:GetAttribute("VoteIndex")==vote then voteHighlight.Adornee=part; voteHighlight.Enabled=true; break end
		end
	end
	spec.Visible=phase == "Live" and not active
	if following and not spec.Visible then restoreCamera() end
	local seconds=math.max(0,math.ceil((workspace:GetAttribute("EndsAt") or 0)-workspace:GetServerTimeNow()))
	timer.Text=if phase == "Waiting" then "—" else string.format("%d:%02d",math.floor(seconds/60),seconds%60)
	title.Text=if phase == "Countdown" then "GET READY" elseif phase == "Results" then (workspace:GetAttribute("Message") or "ROUND OVER") else "ROMAN COLISEUM"
	if phase == "Live" then
		subtitle.Text=(workspace:GetAttribute("Mode") or "FFA").." • "..tostring(workspace:GetAttribute("Remaining") or 0).." remaining"
	else subtitle.Text=workspace:GetAttribute("Message") or "" end
	local id=player:GetAttribute("Item"); local def=Config.Items[id]
	local now=workspace:GetServerTimeNow()
	Hotbar.update(slotButtons,player,UIS.TouchEnabled)
	if (player:GetAttribute("ShieldUntil") or 0)>now then itemHint.Text="SHIELD RAISED"
	elseif (player:GetAttribute("AnchorUntil") or 0)>now then itemHint.Text="ANCHORED"
	elseif def then itemHint.Text=string.upper(def.Name)..(if UIS.TouchEnabled then " · TAP ITEM" else " · F TO USE")
	else itemHint.Text="" end
	inventory.Visible=active
	local adrenalineValue=math.clamp(player:GetAttribute("Adrenaline") or 0,0,Config.Adrenaline.Max)
	adrenaline.Visible=active
	adrenalineFill.Size=UDim2.fromScale(adrenalineValue/Config.Adrenaline.Max,1)
	adrenalineFill.BackgroundColor3=if adrenalineValue>=100 then colors.gold else Color3.fromRGB(202,118,58)
	adrenalineText.Text=if (player:GetAttribute("AdrenalineUntil") or 0)>now then "ADRENALINE RUSH"
		elseif adrenalineValue>=Config.Adrenaline.Max then (if UIS.TouchEnabled then "TAP FOR ADRENALINE RUSH" elseif UIS:GetLastInputType()==Enum.UserInputType.Gamepad1 then "RUSH · D-PAD DOWN" else "ADRENALINE READY · G")
		else "ADRENALINE"
	local hazard=workspace:GetAttribute("Hazard") or ""
	local hazardActiveAt=workspace:GetAttribute("HazardActiveAt") or 0
	local hazardCountdown=math.max(0,math.ceil(hazardActiveAt-now))
	hazardPanel.Visible=phase=="Live" and hazard~=""
	if hazard~="" and now<hazardActiveAt then
		hazardText.Text="⚠  "..(hazard=="Meteor" and "METEOR SHOWER" or "LION RELEASE").." IN "..hazardCountdown.."s"
	else
		hazardText.Text=if hazard=="Meteor" then "⚠  METEOR SHOWER  •  WATCH TELEGRAPHS"
			elseif hazard=="Lions" then "⚠  LIONS RELEASED  •  KEEP MOVING" else ""
	end
	toastPanel.Visible=os.clock() < toastUntil
	local statsFolder=player:FindFirstChild("leaderstats")
	if statsFolder and statsFolder:FindFirstChild("Wins") and statsFolder:FindFirstChild("Coins") then
		statText.Text=statsFolder.Wins.Value.." wins • "..statsFolder.Coins.Value.." coins (session)"
	end
	-- On narrow screens, avoid covering the main round banner.
	stats.Position=if camera.ViewportSize.X < 1000 then UDim2.fromScale(.02,.17) else UDim2.fromScale(.02,.02)
	stats.Visible=active and not toastPanel.Visible and camera.ViewportSize.X>800
	mobility.Visible=UIS.TouchEnabled and active and phase=="Live" and not following
	actionPanel.Visible=UIS.TouchEnabled and not following and phase~="Countdown" and phase~="Results"
	controlHint.Visible=not UIS.TouchEnabled and active and not following
	local pushWait=math.max(0,(cooldown.Push or 0)-os.clock())
	controlHint.Text=if UIS:GetLastInputType()==Enum.UserInputType.Gamepad1 then "R2 PUSH  •  X GRAB  •  L2 ITEM  •  B DASH"
		elseif pushWait>0 then string.format("PUSH %.1fs  •  Q GRAB  •  F USE  •  SHIFT SPRINT  •  X DASH  •  C SLIDE  •  G RUSH",pushWait)
		else "E PUSH  •  Q GRAB  •  F USE  •  SHIFT SPRINT  •  X DASH  •  C SLIDE  •  G RUSH"
	local texts=if UIS.TouchEnabled then {Push="PUSH",Grab="GRAB",UseItem="ITEM"}
		elseif UIS.GamepadEnabled and not UIS.KeyboardEnabled then {Push="PUSH · R2",Grab="GRAB · X",UseItem="ITEM · L2"}
		else {Push="PUSH\nE / Click",Grab="GRAB\nQ",UseItem="ITEM\nF"}
	for kind,b in actionButtons do
		local remaining=(cooldown[kind] or 0)-os.clock()
		b.Text=if remaining > 0 then string.format("%.1fs",remaining) else texts[kind]
		b.BackgroundColor3=if remaining > 0 then colors.bg else colors.soft
	end
	lockButton.Text=if locked then "RSHIFT LOCK: ON" else "RSHIFT LOCK: OFF"
	lockPanel.Visible=UIS.MouseEnabled and not following
	crosshair.Text=if os.clock()<hitUntil then "×" else "+"
	crosshair.TextColor3=if os.clock()<hitUntil then colors.gold else colors.text
	crosshair.Visible=os.clock()<hitUntil or locked or ((id=="Bow" or id=="Mace") and active and not following)
	povButton.Text=if firstPerson then "POV: FIRST" else "POV: THIRD"
	specTitle.Text=if following then "WATCHING "..actorName(following) else "WATCH FROM THE STANDS"
end
workspace:GetAttributeChangedSignal("Phase"):Connect(function()
	updateUI()
end)
local elapsed=0
RunService:BindToRenderStep("UnstableCamera",Enum.RenderPriority.Camera.Value+1,function(dt)
	local camera=workspace.CurrentCamera; if not camera then return end
	local char=player.Character; local hum=char and char:FindFirstChildOfClass("Humanoid")
	local root=char and char:FindFirstChild("HumanoidRootPart")
	if hum and root then
		local showRange=player:GetAttribute("InRound")==true and player:GetAttribute("Item")=="Mace"
		updateRange(root,showRange)
	else updateRange(nil,false) end
	local canLock=wantLock and UIS.MouseEnabled and not following and not GuiService.MenuIsOpen and not UIS:GetFocusedTextBox() and hum and hum.Health > 0
	if canLock then
		locked=true; UIS.MouseBehavior=Enum.MouseBehavior.LockCenter
		hum.CameraOffset=Vector3.new(1.7,0,0); hum.AutoRotate=false
		if root and not root.Anchored and not hum.PlatformStand then
			local look=camera.CFrame.LookVector; local flat=Vector3.new(look.X,0,look.Z)
			if flat.Magnitude > .01 then root.CFrame=CFrame.lookAt(root.Position,root.Position+flat) end
		end
	elseif locked then
		locked=false; UIS.MouseBehavior=Enum.MouseBehavior.Default
		if hum then hum.CameraOffset=Vector3.zero; hum.AutoRotate=true end
	end
	if following then
		local target=character(following); local th=target and target:FindFirstChildOfClass("Humanoid")
		local head=target and target:FindFirstChild("Head")
		if not following:GetAttribute("InRound") or not th or th.Health <= 0 then cycle(1)
		elseif firstPerson and head then
			camera.CameraType=Enum.CameraType.Scriptable; camera.CFrame=head.CFrame*CFrame.new(0,.15,-.8)
		else camera.CameraType=Enum.CameraType.Custom; camera.CameraSubject=th end
	end
	elapsed+=dt; if elapsed >= .1 then elapsed=0; updateUI() end
end)
updateUI(); action:FireServer("Snapshot")
