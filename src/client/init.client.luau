--!nonstrict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local CollectionService=game:GetService("CollectionService")
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
local inventory=panel("Inventory",UDim2.fromOffset(430,92),UDim2.fromScale(.5,.985),Vector2.new(.5,1))
inventory.BackgroundTransparency=.22
local itemHint=label(inventory,"R / Y pickup  •  1–3 select  •  F use",UDim2.new(1,-12,0,20),UDim2.fromOffset(6,2),11)
itemHint.TextColor3=Color3.fromRGB(205,195,175)
local slotButtons={}; local slotStrokes={}
for i=1,3 do
	local slot=i
	local x=8+(i-1)*139
	local b=button(inventory,tostring(i).."  EMPTY",UDim2.fromOffset(132,60),UDim2.fromOffset(x,25),function()
		action:FireServer("SelectSlot",slot)
	end)
	b.TextSize=13; b.TextWrapped=true
	local stroke=Instance.new("UIStroke"); stroke.Thickness=1.5; stroke.Transparency=.5; stroke.Color=colors.gold; stroke.Parent=b
	slotButtons[i]=b; slotStrokes[i]=stroke
end
local adrenaline=panel("Adrenaline",UDim2.fromOffset(320,28),UDim2.fromScale(.5,.82),Vector2.new(.5,1))
adrenaline.BackgroundTransparency=.18
local adrenalineTrack=Instance.new("Frame"); adrenalineTrack.Size=UDim2.new(1,-8,1,-8); adrenalineTrack.Position=UDim2.fromOffset(4,4)
adrenalineTrack.BackgroundColor3=Color3.fromRGB(45,43,39); adrenalineTrack.BorderSizePixel=0; adrenalineTrack.Parent=adrenaline; roundCorner(adrenalineTrack,7)
local adrenalineFill=Instance.new("Frame"); adrenalineFill.Size=UDim2.fromScale(0,1); adrenalineFill.BackgroundColor3=Color3.fromRGB(202,118,58)
adrenalineFill.BorderSizePixel=0; adrenalineFill.Parent=adrenalineTrack; roundCorner(adrenalineFill,7)
local adrenalineText=label(adrenalineTrack,"ADRENALINE 0%",UDim2.fromScale(1,1),UDim2.new(),11)
local hazardPanel=panel("Hazard",UDim2.fromOffset(420,32),UDim2.fromScale(.5,.115),Vector2.new(.5,0))
hazardPanel.Visible=false; hazardPanel.BackgroundTransparency=.16
local hazardText=label(hazardPanel,"",UDim2.new(1,-12,1,0),UDim2.fromOffset(6,0),13)
local crosshair=label(gui,"+",UDim2.fromOffset(24,24),UDim2.new(.5,-12,.5,-12),24)
crosshair.TextTransparency=.15
local lockPanel=panel("Lock",UDim2.fromOffset(190,32),UDim2.fromScale(.02,.97),Vector2.new(0,1))
local lockButton=button(lockPanel,"RSHIFT LOCK: OFF",UDim2.fromScale(1,1),UDim2.new(),function() wantLock=not wantLock end)
lockPanel.BackgroundTransparency=1; lockButton.BackgroundTransparency=.35
local controlHint=label(gui,"E PUSH  •  Q GRAB  •  F USE  •  SHIFT SPRINT  •  X DASH  •  C SLIDE  •  G RUSH",UDim2.fromOffset(670,22),UDim2.new(.5,-335,1,-120),11)
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
	elseif key == Enum.KeyCode.X or key == Enum.KeyCode.ButtonB then send("Dash")
	elseif key == Enum.KeyCode.C then send("Slide")
	elseif key == Enum.KeyCode.G then send("Adrenaline")
	elseif key == Enum.KeyCode.E or key == Enum.KeyCode.ButtonR2 or input.UserInputType == Enum.UserInputType.MouseButton1 then send("Push")
	elseif key == Enum.KeyCode.Q or key == Enum.KeyCode.ButtonX then send("Grab")
	elseif key == Enum.KeyCode.F or key == Enum.KeyCode.ButtonL2 then send("UseItem")
	end
end)
UIS.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift then action:FireServer("Sprint",false) end
end)
player.CharacterAdded:Connect(function() restoreCamera(); wantLock=false; action:FireServer("Sprint",false) end)
local effects=Instance.new("Folder"); effects.Name="ArenaLocalEffects"; effects.Parent=workspace
local maceRange=Instance.new("Part"); maceRange.Name="MaceRange"; maceRange.Anchored=true
maceRange.CanCollide=false; maceRange.CanTouch=false; maceRange.CanQuery=false
maceRange.Shape=Enum.PartType.Cylinder; maceRange.Material=Enum.Material.Neon
maceRange.Color=Color3.fromRGB(205,156,83); maceRange.Transparency=1
maceRange.Size=Vector3.new(.05,Config.Combat.MaceLockRange*2,Config.Combat.MaceLockRange*2); maceRange.Parent=effects
local animatedBots={}
local function registerBot(bot)
	task.spawn(function()
		local torso=bot:WaitForChild("Torso",5); if not torso then return end
		local joints={}
		for _,name in {"Left Hip","Right Hip","Left Shoulder","Right Shoulder"} do
			local joint=torso:WaitForChild(name,5); if joint then joints[name]=joint end
		end
		if bot.Parent and CollectionService:HasTag(bot,"ArenaBot") then animatedBots[bot]=joints end
	end)
end
for _,bot in CollectionService:GetTagged("ArenaBot") do registerBot(bot) end
CollectionService:GetInstanceAddedSignal("ArenaBot"):Connect(registerBot)
CollectionService:GetInstanceRemovedSignal("ArenaBot"):Connect(function(bot) animatedBots[bot]=nil end)

local playerRig={character=nil,joints={}}
local function playerJoints()
	local char=player.Character
	if char~=playerRig.character then
		playerRig.character=char
		playerRig.joints={}
		if char then
			for _,d in char:GetDescendants() do
				if d:IsA("Motor6D") then
					local n=string.lower(d.Name)
					if string.find(n,"shoulder") or string.find(n,"waist") or string.find(n,"rootjoint") then
						playerRig.joints[d.Name]=d
					end
				end
			end
		end
	end
	return playerRig.joints
end

local function actionPose(joints,actor,walkAmount,phase)
	local now=workspace:GetServerTimeNow()
	local swinging=(actor:GetAttribute("SwingUntil") or 0)>now
	local grabbing=(actor:GetAttribute("GrabUntil") or 0)>now
	local picking=(actor:GetAttribute("PickupUntil") or 0)>now
	local using=(actor:GetAttribute("ItemActionUntil") or 0)>now
	for name,joint in joints do
		local lower=string.lower(name)
		local left=string.find(lower,"left")~=nil
		local shoulder=string.find(lower,"shoulder")~=nil
		local waist=string.find(lower,"waist")~=nil or string.find(lower,"rootjoint")~=nil
		local target=CFrame.identity
		if shoulder then
			local stride=math.sin(phase)*(if left then 1 else -1)*.34*walkAmount
			target=CFrame.Angles(stride,0,0)
			if swinging then
				if left then target=CFrame.Angles(-.35,0,-.18) else target=CFrame.Angles(-1.28,0,.12) end
			elseif grabbing then
				target=CFrame.Angles(-1.02,0,if left then -.18 else .18)
			elseif picking then
				target=CFrame.Angles(-.82,0,if left then -.12 else .12)
			elseif using then
				target=CFrame.Angles(if left then -.55 else -1.0,0,if left then -.08 else .1)
			end
		elseif waist and (swinging or grabbing or picking or using) then
			target=CFrame.Angles(if picking then .13 else -.08,0,if swinging then -.12 else 0)
		end
		joint.Transform=joint.Transform:Lerp(target,.28)
	end
end
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

	if kind=="DangerCircle" then
		local radius=if typeof(b)=="number" then b else 6
		local ring=basePart(); ring.Name="DangerTelegraph"; ring.Shape=Enum.PartType.Cylinder
		ring.Material=Enum.Material.Neon; ring.Color=Color3.fromRGB(231,108,66); ring.Transparency=.45
		ring.Size=Vector3.new(.07,radius*2,radius*2)
		ring.CFrame=CFrame.new(a-Vector3.new(0,2.7,0))*CFrame.Angles(0,0,math.pi/2)
		local pulse=TweenService:Create(ring,TweenInfo.new(.55,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Transparency=.12})
		pulse:Play(); Debris:AddItem(ring,1.2)
		return
	elseif kind=="MeteorIncoming" and typeof(b)=="Vector3" then
		local rock=basePart(); rock.Shape=Enum.PartType.Ball; rock.Size=Vector3.one*3.8
		rock.Material=Enum.Material.Rock; rock.Color=Color3.fromRGB(83,55,40); rock.Position=a
		local fire=Instance.new("Fire"); fire.Size=5; fire.Heat=4; fire.Parent=rock
		TweenService:Create(rock,TweenInfo.new(1.12,Enum.EasingStyle.Linear),{Position=b}):Play()
		Debris:AddItem(rock,1.18); return
	elseif kind=="MeteorImpact" then
		burst(a,Color3.fromRGB(225,119,58),24,4.5); return
	elseif kind=="Mace" then
		line(a,b,.42,Color3.fromRGB(201,151,79),.1); return
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
	if kind == "Toast" then toast(a)
	elseif kind == "Cooldown" then cooldown[a]=os.clock()+b
	else effect(kind,a,b) end
end)
local function updateUI()
	local camera=workspace.CurrentCamera; if not camera then return end
	local scale=math.min(1,camera.ViewportSize.X/620,camera.ViewportSize.Y/560)
	for _,s in scales do s.Scale=scale end
	local phase=workspace:GetAttribute("Phase") or "Waiting"
	local active=player:GetAttribute("InRound") == true
	spec.Visible=phase == "Live" and not active
	if following and not spec.Visible then restoreCamera() end
	local seconds=math.max(0,math.ceil((workspace:GetAttribute("EndsAt") or 0)-workspace:GetServerTimeNow()))
	timer.Text=if phase == "Waiting" then "—" else tostring(seconds)
	title.Text=if phase == "Countdown" then "GET READY" elseif phase == "Results" then "ROUND OVER" else "ROMAN COLISEUM"
	if phase == "Live" then
		subtitle.Text=(workspace:GetAttribute("Mode") or "FFA").." • "..tostring(workspace:GetAttribute("Remaining") or 0).." remaining"
	else subtitle.Text=workspace:GetAttribute("Message") or "" end
	local id=player:GetAttribute("Item"); local def=Config.Items[id]
	local now=workspace:GetServerTimeNow()
	local activeSlot=player:GetAttribute("ActiveSlot") or 1
	for i=1,3 do
		local slotId=player:GetAttribute("Inventory"..i)
		local uses=player:GetAttribute("Inventory"..i.."Uses") or 0
		local slotDef=Config.Items[slotId]
		slotButtons[i].Text=tostring(i).."  "..(slotDef and (string.upper(slotDef.Name).."  ×"..uses) or "EMPTY")
		slotButtons[i].TextColor3=slotDef and slotDef.Color or Color3.fromRGB(164,157,144)
		slotButtons[i].BackgroundColor3=if i==activeSlot then Color3.fromRGB(77,67,50) else colors.soft
		slotStrokes[i].Transparency=if i==activeSlot then .05 else .72
		slotStrokes[i].Thickness=if i==activeSlot then 2.5 else 1
	end
	if (player:GetAttribute("ShieldUntil") or 0)>now then itemHint.Text="SHIELD ACTIVE  •  next hit blocked"
	elseif (player:GetAttribute("AnchorUntil") or 0)>now then itemHint.Text="ANCHORED  •  reduced knockback"
	elseif def then itemHint.Text=def.Hint.."  •  F to use"
	else itemHint.Text="R / Y pickup  •  1–3 select  •  max 3 items" end
	inventory.Visible=active
	local adrenalineValue=math.clamp(player:GetAttribute("Adrenaline") or 0,0,Config.Adrenaline.Max)
	adrenaline.Visible=active
	adrenalineFill.Size=UDim2.fromScale(adrenalineValue/Config.Adrenaline.Max,1)
	adrenalineText.Text=if (player:GetAttribute("AdrenalineUntil") or 0)>now then "ADRENALINE RUSH"
		elseif adrenalineValue>=Config.Adrenaline.Max then "ADRENALINE READY  •  G"
		else "ADRENALINE  "..math.floor(adrenalineValue).."%"
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
	actionPanel.Visible=UIS.TouchEnabled and not following and phase~="Countdown" and phase~="Results"
	controlHint.Visible=not UIS.TouchEnabled and active and not following
	local pushWait=math.max(0,(cooldown.Push or 0)-os.clock())
	controlHint.Text=if UIS.GamepadEnabled and not UIS.KeyboardEnabled then "R2 PUSH  •  X GRAB  •  L2 ITEM  •  B DASH"
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
	crosshair.Visible=locked or ((id=="Bow" or id=="Mace") and active and not following)
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
		local speed=Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z).Magnitude
		actionPose(playerJoints(),player,math.clamp(speed/20,0,1),os.clock()*10)
		local showRange=player:GetAttribute("InRound")==true and player:GetAttribute("Item")=="Mace"
		if showRange then
			maceRange.Transparency=.82
			maceRange.CFrame=CFrame.new(root.Position-Vector3.new(0,2.8,0))*CFrame.Angles(0,0,math.pi/2)
		else maceRange.Transparency=1 end
	else maceRange.Transparency=1 end
	for bot,joints in animatedBots do
		local botRoot=bot:FindFirstChild("HumanoidRootPart")
		local botHum=bot:FindFirstChildOfClass("Humanoid")
		if botRoot and botHum then
			local moving=botHum.MoveDirection.Magnitude
			-- Animation is cosmetic and local; combat and movement stay server-owned.
			local velocity=botRoot.AssemblyLinearVelocity
			if moving<.1 then moving=math.clamp(Vector3.new(velocity.X,0,velocity.Z).Magnitude/17,0,1) end
			local stride=math.sin(os.clock()*10+(bot:GetAttribute("ActorId") or 0))*.5*moving
			if botHum.PlatformStand then stride=0 end
			actionPose(joints,bot,moving,os.clock()*10+(bot:GetAttribute("ActorId") or 0))
		end
	end
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
