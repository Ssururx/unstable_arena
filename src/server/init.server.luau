--!nonstrict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Lighting=game:GetService("Lighting")
local Config=require(ReplicatedStorage.Shared.Config)
local Arena=require(script.ArenaService)
local Round=require(script.RoundService)
local Combat=require(script.PushService)
local Items=require(script.ItemService)

-- Remove only the stock template floor/spawn; leave user-authored scenery alone.
for _,name in {"Baseplate","SpawnLocation"} do
	local part=workspace:FindFirstChild(name)
	if part and part:IsA("BasePart") then part:Destroy() end
end
local old=workspace:FindFirstChild("UnstableArenaWorld"); if old then old:Destroy() end
local folder=ReplicatedStorage:FindFirstChild("Remotes")
if not folder then folder=Instance.new("Folder"); folder.Name="Remotes"; folder.Parent=ReplicatedStorage end
local function remote(name)
	local existing=folder:FindFirstChild(name)
	if existing then assert(existing:IsA("RemoteEvent"),name.." must be a RemoteEvent"); return existing end
	local event=Instance.new("RemoteEvent"); event.Name=name; event.Parent=folder; return event
end
local action=remote("Action"); local fx=remote("FX"); local state=remote("RoundState")
Lighting.ClockTime=15; Lighting.Brightness=2
Lighting.Ambient=Color3.fromRGB(110,108,124)
Lighting.OutdoorAmbient=Color3.fromRGB(145,145,155)
workspace:SetAttribute("Version",Config.Version)
workspace:SetAttribute("Phase","Waiting")
local arena=Arena.new(fx)
local round=Round.new(arena,state,fx)
local combat=Combat.new(round,arena,fx)
local items=Items.new(round,arena,combat,fx)
round.combat=combat; round.items=items
Players.PlayerAdded:Connect(function(p) round:AddPlayer(p) end)
Players.PlayerRemoving:Connect(function(p) round:RemovePlayer(p) end)
for _,p in Players:GetPlayers() do round:AddPlayer(p) end
action.OnServerEvent:Connect(function(p,kind,arg,extra)
	if typeof(kind) ~= "string" or not combat:Ready(p,"Remote",.06) then return end
	if kind == "Push" then combat:Push(p)
	elseif kind == "Grab" then combat:Grab(p)
	elseif kind == "UseItem" then items:Use(p,arg)
	elseif kind == "Vote" then round:Vote(p,arg,extra)
	elseif kind == "Snapshot" and combat:Ready(p,"Snapshot",1) then round:Broadcast()
	end
end)
RunService.Heartbeat:Connect(function() arena:StepPractice() end)
task.spawn(function() round:Run() end)
print("[UnstableArena] "..Config.Version.." ready • Click/E push • Q grab • F item • Shift mouse lock")
