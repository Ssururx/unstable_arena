--!nonstrict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local Config=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local player=Players.LocalPlayer
local remotes=ReplicatedStorage:WaitForChild("Remotes")
local action=remotes:WaitForChild("Action")
local fx=remotes:WaitForChild("FX")
local state=remotes:WaitForChild("RoundState")
local colors={bg=Color3.fromRGB(23,27,35),soft=Color3.fromRGB(43,49,61),text=Color3.fromRGB(247,240,222),gold=Color3.fromRGB(245,192,102)}
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
local top=panel("Round",UDim2.fromOffset(450,85),UDim2.fromScale(.5,.02),Vector2.new(.5,0))
local title=label(top,"UNSTABLE ARENA",UDim2.new(1,-20,0,28),UDim2.fromOffset(10,7),19)
local subtitle=label(top,"Joining arena…",UDim2.new(1,-85,0,34),UDim2.fromOffset(12,39),13)
subtitle.TextXAlignment=Enum.TextXAlignment.Left
local timer=label(top,"",UDim2.fromOffset(65,38),UDim2.new(1,-75,0,37),30); timer.TextColor3=colors.gold
local stats=panel("SessionStats",UDim2.fromOffset(210,28),UDim2.fromScale(.02,.02),Vector2.zero)
local statText=label(stats,"0 wins • 0 coins",UDim2.fromScale(1,1),UDim2.new(),12)
local toastPanel=panel("Toast",UDim2.fromOffset(480,46),UDim2.fromScale(.5,.2),Vector2.new(.5,0))
toastPanel.Visible=false
local toastText=label(toastPanel,"",UDim2.new(1,-20,1,-8),UDim2.fromOffset(10,4),16)
local toastUntil=0
local function toast(message)
	toastText.Text=message; toastUntil=os.clock()+3; toastPanel.Visible=true
end
local vote=panel("Vote",UDim2.fromOffset(540,213),UDim2.fromScale(.5,.5),Vector2.new(.5,.5))
label(vote,"NEXT ARENA",UDim2.new(1,0,0,32),UDim2.fromOffset(0,8),18)
local mapButtons={}; local modeButtons={}; local mapCounts={0,0}; local modeCounts={0,0,0}
local selectedMap=nil; local selectedMode=nil
for i,map in Config.Maps do
	mapButtons[i]=button(vote,map.Name,UDim2.fromOffset(250,65),UDim2.fromOffset(15+(i-1)*260,48),function()
		selectedMap=i; action:FireServer("Vote","map",i)
	end)
	mapButtons[i].TextWrapped=true
end
label(vote,"TEAM SIZE",UDim2.new(1,0,0,24),UDim2.fromOffset(0,119),12)
for i,mode in Config.Modes do
	modeButtons[i]=button(vote,mode,UDim2.fromOffset(160,42),UDim2.fromOffset(20+(i-1)*170,154),function()
		selectedMode=i; action:FireServer("Vote","mode",i)
	end)
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
local inventory=panel("Inventory",UDim2.fromOffset(390,65),UDim2.fromScale(.5,.97),Vector2.new(.5,1))
local itemName=label(inventory,"EMPTY HANDS",UDim2.new(1,-12,0,26),UDim2.fromOffset(6,3),16)
local itemHint=label(inventory,"R / Y / tap a pickup • carry one item",UDim2.new(1,-12,0,29),UDim2.fromOffset(6,29),12)
local crosshair=label(gui,"+",UDim2.fromOffset(24,24),UDim2.new(.5,-12,.5,-12),24)
crosshair.TextTransparency=.15
local lockPanel=panel("Lock",UDim2.fromOffset(190,32),UDim2.fromScale(.02,.97),Vector2.new(0,1))
local lockButton=button(lockPanel,"SHIFT LOCK: OFF",UDim2.fromScale(1,1),UDim2.new(),function() wantLock=not wantLock end)
local spec=panel("Spectator",UDim2.fromOffset(450,88),UDim2.fromScale(.5,.82),Vector2.new(.5,1))
local specTitle=label(spec,"WATCH FROM THE STANDS",UDim2.new(1,-12,0,26),UDim2.fromOffset(6,3),14)
local function subjects()
	local list={}
	for _,p in Players:GetPlayers() do
		if p ~= player and p:GetAttribute("InRound") and p.Character and p.Character:FindFirstChildOfClass("Humanoid") then table.insert(list,p) end
	end
	table.sort(list,function(a,b) return a.UserId < b.UserId end)
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
	if key == Enum.KeyCode.LeftShift or key == Enum.KeyCode.RightShift then wantLock=not wantLock
	elseif key == Enum.KeyCode.E or key == Enum.KeyCode.ButtonR2 or input.UserInputType == Enum.UserInputType.MouseButton1 then send("Push")
	elseif key == Enum.KeyCode.Q or key == Enum.KeyCode.ButtonX then send("Grab")
	elseif key == Enum.KeyCode.F or key == Enum.KeyCode.ButtonL2 then send("UseItem")
	end
end)
player.CharacterAdded:Connect(function() restoreCamera(); wantLock=false end)
state.OnClientEvent:Connect(function(data)
	mapCounts=data.maps or mapCounts; modeCounts=data.modes or modeCounts
end)
local effects=Instance.new("Folder"); effects.Name="ArenaLocalEffects"; effects.Parent=workspace
local function effect(kind,a,b)
	local camera=workspace.CurrentCamera
	if typeof(a) ~= "Vector3" or not camera or (camera.CFrame.Position-a).Magnitude > 230 or #effects:GetChildren() >= 70 then return end
	local part=Instance.new("Part"); part.Anchored=true; part.CanCollide=false; part.CanTouch=false; part.CanQuery=false
	part.Material=Enum.Material.Neon; part.Color=colors.gold; part.Transparency=.25
	if kind == "Arrow" or kind == "Grab" then
		if typeof(b) ~= "Vector3" or (b-a).Magnitude < .01 then part:Destroy(); return end
		part.Size=Vector3.new(.12,.12,(b-a).Magnitude); part.CFrame=CFrame.lookAt((a+b)/2,b)
		part.Color=if kind == "Arrow" then Color3.fromRGB(211,137,255) else Color3.fromRGB(105,220,240)
	else
		part.Shape=Enum.PartType.Ball; part.Size=Vector3.one*1.3
		part.Position=if kind == "Swing" and typeof(b) == "Vector3" then a+b*3 else a
		if typeof(b) == "Color3" then part.Color=b end
		if kind == "Break" then part.Color=Color3.fromRGB(170,130,98) end
		if kind == "Block" then part.Color=Color3.fromRGB(90,175,255) end
		TweenService:Create(part,TweenInfo.new(.25),{Size=Vector3.one*(if kind == "Break" then 8 else 4)}):Play()
	end
	part.Parent=effects
	TweenService:Create(part,TweenInfo.new(.25),{Transparency=1}):Play(); Debris:AddItem(part,.3)
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
	vote.Visible=phase == "Vote"
	spec.Visible=phase == "Live" and not active
	if following and not spec.Visible then restoreCamera() end
	local seconds=math.max(0,math.ceil((workspace:GetAttribute("EndsAt") or 0)-workspace:GetServerTimeNow()))
	timer.Text=if phase == "Waiting" then "—" else tostring(seconds)
	title.Text=if phase == "Live" then (workspace:GetAttribute("MapName") or "UNSTABLE ARENA")
		elseif phase == "Vote" then "CHOOSE THE NEXT ARENA" elseif phase == "Countdown" then "GET READY"
		elseif phase == "Results" then "ROUND OVER" else "UNSTABLE ARENA"
	if phase == "Live" then
		subtitle.Text=(workspace:GetAttribute("Mode") or "FFA").." • "..tostring(workspace:GetAttribute("Remaining") or 0).." remaining"
	else subtitle.Text=workspace:GetAttribute("Message") or "" end
	for i,b in mapButtons do
		b.Text=Config.Maps[i].Name.."  ("..mapCounts[i]..")\n"..Config.Maps[i].Tag
		b.BackgroundColor3=if selectedMap == i then Color3.fromRGB(107,77,37) else colors.soft
	end
	for i,b in modeButtons do
		b.Text=Config.Modes[i].."  ("..modeCounts[i]..")"
		b.BackgroundColor3=if selectedMode == i then Color3.fromRGB(107,77,37) else colors.soft
	end
	local id=player:GetAttribute("Item"); local def=Config.Items[id]
	itemName.Text=if def then def.Name.." ×"..tostring(player:GetAttribute("ItemUses") or 1) else "EMPTY HANDS"
	itemName.TextColor3=if def then def.Color else colors.text
	local now=workspace:GetServerTimeNow()
	if (player:GetAttribute("ShieldUntil") or 0) > now then itemHint.Text="SHIELD ACTIVE • blocks one hit"
	elseif (player:GetAttribute("AnchorUntil") or 0) > now then itemHint.Text="ANCHORED • your slab is under extra stress"
	else itemHint.Text=if def then def.Hint else "R / Y / tap a pickup • carry one item" end
	inventory.Visible=active or phase == "Vote"
	toastPanel.Visible=os.clock() < toastUntil
	local statsFolder=player:FindFirstChild("leaderstats")
	if statsFolder and statsFolder:FindFirstChild("Wins") and statsFolder:FindFirstChild("Coins") then
		statText.Text=statsFolder.Wins.Value.." wins • "..statsFolder.Coins.Value.." coins (session)"
	end
	-- On narrow screens, avoid covering the main round banner.
	stats.Position=if camera.ViewportSize.X < 1000 then UDim2.fromScale(.02,.17) else UDim2.fromScale(.02,.02)
	stats.Visible=not toastPanel.Visible
	actionPanel.Visible=not following and not vote.Visible and phase ~= "Countdown" and phase ~= "Results"
	local texts=if UIS.TouchEnabled then {Push="PUSH",Grab="GRAB",UseItem="ITEM"}
		elseif UIS.GamepadEnabled and not UIS.KeyboardEnabled then {Push="PUSH · R2",Grab="GRAB · X",UseItem="ITEM · L2"}
		else {Push="PUSH\nE / Click",Grab="GRAB\nQ",UseItem="ITEM\nF"}
	for kind,b in actionButtons do
		local remaining=(cooldown[kind] or 0)-os.clock()
		b.Text=if remaining > 0 then string.format("%.1fs",remaining) else texts[kind]
		b.BackgroundColor3=if remaining > 0 then colors.bg else colors.soft
	end
	lockButton.Text=if locked then "SHIFT LOCK: ON" else "SHIFT LOCK: OFF"
	lockPanel.Visible=UIS.MouseEnabled and not following and not vote.Visible
	crosshair.Visible=locked or (id == "Bow" and active and not following)
	povButton.Text=if firstPerson then "POV: FIRST" else "POV: THIRD"
	specTitle.Text=if following then "WATCHING "..following.DisplayName else "WATCH FROM THE STANDS"
end
workspace:GetAttributeChangedSignal("Phase"):Connect(function()
	if workspace:GetAttribute("Phase") == "Vote" then selectedMap=nil; selectedMode=nil; mapCounts={0,0}; modeCounts={0,0,0} end
	updateUI()
end)
local elapsed=0
RunService:BindToRenderStep("UnstableCamera",Enum.RenderPriority.Camera.Value+1,function(dt)
	local camera=workspace.CurrentCamera; if not camera then return end
	local char=player.Character; local hum=char and char:FindFirstChildOfClass("Humanoid")
	local root=char and char:FindFirstChild("HumanoidRootPart")
	local canLock=wantLock and UIS.MouseEnabled and not following and not vote.Visible and not GuiService.MenuIsOpen and not UIS:GetFocusedTextBox() and hum and hum.Health > 0
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
		local target=following.Character; local th=target and target:FindFirstChildOfClass("Humanoid")
		local head=target and target:FindFirstChild("Head")
		if not following:GetAttribute("InRound") or not th or th.Health <= 0 then cycle(1)
		elseif firstPerson and head then
			camera.CameraType=Enum.CameraType.Scriptable; camera.CFrame=head.CFrame*CFrame.new(0,.15,-.8)
		else camera.CameraType=Enum.CameraType.Custom; camera.CameraSubject=th end
	end
	elapsed+=dt; if elapsed >= .1 then elapsed=0; updateUI() end
end)
updateUI(); action:FireServer("Snapshot")
toast("Welcome! Push with E or click • Shift locks the mouse")
