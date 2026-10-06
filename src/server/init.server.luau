--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ArenaService = require(script.ArenaService)
local PushService = require(script.PushService)
local RoundService = require(script.RoundService)

local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate then
	baseplate:Destroy()
end

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end

local pushRemote = remotes:FindFirstChild("Push") :: RemoteEvent?
if not pushRemote then
	pushRemote = Instance.new("RemoteEvent")
	pushRemote.Name = "Push"
	pushRemote.Parent = remotes
end

local stateRemote = remotes:FindFirstChild("RoundState") :: RemoteEvent?
if not stateRemote then
	stateRemote = Instance.new("RemoteEvent")
	stateRemote.Name = "RoundState"
	stateRemote.Parent = remotes
end

local arena = ArenaService.new()
arena:Build()

local roundService = RoundService.new(arena, stateRemote)
PushService.new(pushRemote, function(player)
	return roundService:IsActive(player)
end)

task.spawn(function()
	roundService:Run()
end)
