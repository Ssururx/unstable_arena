--!strict

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local pushRemote = remotes:WaitForChild("Push") :: RemoteEvent
local stateRemote = remotes:WaitForChild("RoundState") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "PrototypeUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local status = Instance.new("TextLabel")
status.Name = "Status"
status.AnchorPoint = Vector2.new(0.5, 0)
status.Position = UDim2.fromScale(0.5, 0.045)
status.Size = UDim2.fromOffset(460, 74)
status.BackgroundColor3 = Color3.fromRGB(18, 16, 21)
status.BackgroundTransparency = 0.16
status.BorderSizePixel = 0
status.Font = Enum.Font.GothamBold
status.TextColor3 = Color3.fromRGB(245, 239, 224)
status.TextScaled = true
status.Text = "UNSTABLE ARENA"
status.Parent = gui

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 12)
statusCorner.Parent = status

local statusPadding = Instance.new("UIPadding")
statusPadding.PaddingLeft = UDim.new(0, 16)
statusPadding.PaddingRight = UDim.new(0, 16)
statusPadding.PaddingTop = UDim.new(0, 8)
statusPadding.PaddingBottom = UDim.new(0, 8)
statusPadding.Parent = status

local hint = Instance.new("TextLabel")
hint.AnchorPoint = Vector2.new(0.5, 1)
hint.Position = UDim2.fromScale(0.5, 0.97)
hint.Size = UDim2.fromOffset(440, 32)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.GothamMedium
hint.TextColor3 = Color3.fromRGB(230, 220, 198)
hint.TextSize = 18
hint.Text = "E / R2 / PUSH • Face a nearby player"
hint.Parent = gui

local spectatorBar = Instance.new("Frame")
spectatorBar.AnchorPoint = Vector2.new(0.5, 1)
spectatorBar.Position = UDim2.fromScale(0.5, 0.91)
spectatorBar.Size = UDim2.fromOffset(430, 48)
spectatorBar.BackgroundColor3 = Color3.fromRGB(18, 16, 21)
spectatorBar.BackgroundTransparency = 0.16
spectatorBar.BorderSizePixel = 0
spectatorBar.Visible = false
spectatorBar.Parent = gui

local spectatorCorner = Instance.new("UICorner")
spectatorCorner.CornerRadius = UDim.new(0, 10)
spectatorCorner.Parent = spectatorBar

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 8)
layout.Parent = spectatorBar

local function makeButton(text: string, width: number): TextButton
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(width, 36)
	button.BackgroundColor3 = Color3.fromRGB(92, 72, 55)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = Color3.fromRGB(255, 244, 219)
	button.TextSize = 14
	button.Text = text
	button.Parent = spectatorBar

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button
	return button
end

local arenaButton = makeButton("ARENA", 100)
local nextButton = makeButton("SPECTATE", 150)
local povButton = makeButton("POV: THIRD", 140)

local lastLocalPush = 0
local currentPhase = "Booting"
local followedPlayer: Player? = nil
local firstPerson = false

local function ownHumanoid(): Humanoid?
	local character = player.Character
	return if character then character:FindFirstChildOfClass("Humanoid") else nil
end

local function stopSpectating()
	followedPlayer = nil
	firstPerson = false
	povButton.Text = "POV: THIRD"
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = ownHumanoid()
end

local function validTargets(): { Player }
	local targets = {}
	for _, candidate in Players:GetPlayers() do
		if candidate ~= player and candidate:GetAttribute("InRound") == true then
			local character = candidate.Character
			local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
			if humanoid and humanoid.Health > 0 then
				table.insert(targets, candidate)
			end
		end
	end
	return targets
end

local function followNextPlayer()
	local targets = validTargets()
	if #targets == 0 then
		stopSpectating()
		return
	end

	local currentIndex = table.find(targets, followedPlayer)
	local nextIndex = if currentIndex then (currentIndex % #targets) + 1 else 1
	followedPlayer = targets[nextIndex]
	firstPerson = false
	povButton.Text = "POV: THIRD"

	local humanoid = followedPlayer.Character
		and followedPlayer.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = humanoid
	end
	nextButton.Text = followedPlayer.DisplayName
end

local function updateSpectatorVisibility()
	local visible = player:GetAttribute("InRound") ~= true and currentPhase == "Live"
	spectatorBar.Visible = visible
	hint.Visible = not visible
	if not visible then
		stopSpectating()
		nextButton.Text = "SPECTATE"
	end
end

arenaButton.Activated:Connect(function()
	stopSpectating()
	nextButton.Text = "SPECTATE"
end)

nextButton.Activated:Connect(followNextPlayer)

povButton.Activated:Connect(function()
	if not followedPlayer then
		followNextPlayer()
	end
	if followedPlayer then
		firstPerson = not firstPerson
		povButton.Text = if firstPerson then "POV: FIRST" else "POV: THIRD"
	end
end)

player:GetAttributeChangedSignal("InRound"):Connect(updateSpectatorVisibility)

local function onPushAction(_: string, inputState: Enum.UserInputState)
	if inputState ~= Enum.UserInputState.Begin or player:GetAttribute("InRound") ~= true then
		return Enum.ContextActionResult.Pass
	end

	local now = os.clock()
	if now - lastLocalPush < Config.Push.Cooldown then
		return Enum.ContextActionResult.Sink
	end

	lastLocalPush = now
	pushRemote:FireServer()
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction(
	"Push",
	onPushAction,
	true,
	Enum.KeyCode.E,
	Enum.KeyCode.ButtonR2
)
ContextActionService:SetTitle("Push", "PUSH")
ContextActionService:SetPosition("Push", UDim2.fromScale(0.84, 0.72))

stateRemote.OnClientEvent:Connect(function(data)
	currentPhase = data.phase
	local message = data.message or data.phase
	local timeText = if data.timeRemaining > 0 then "  " .. tostring(data.timeRemaining) else ""
	local remainingText = if data.phase == "Live"
		then "  •  " .. tostring(data.remaining) .. " LEFT"
		else ""
	status.Text = string.upper(message) .. timeText .. remainingText
	updateSpectatorVisibility()
end)

pushRemote.OnClientEvent:Connect(function(eventName, fromPosition: Vector3, toPosition: Vector3)
	if eventName ~= "Impact" then
		return
	end

	local effect = Instance.new("Part")
	effect.Name = "PushImpact"
	effect.Shape = Enum.PartType.Ball
	effect.Size = Vector3.new(1.3, 1.3, 1.3)
	effect.CFrame = CFrame.new(fromPosition:Lerp(toPosition, 0.7))
	effect.Anchored = true
	effect.CanCollide = false
	effect.Material = Enum.Material.Neon
	effect.Color = Color3.fromRGB(255, 217, 124)
	effect.Transparency = 0.1
	effect.Parent = workspace

	local tween = TweenService:Create(
		effect,
		TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = Vector3.new(5, 5, 5),
			Transparency = 1,
		}
	)
	tween:Play()
	tween.Completed:Once(function()
		effect:Destroy()
	end)
end)

RunService.RenderStepped:Connect(function()
	if not followedPlayer then
		return
	end

	if followedPlayer:GetAttribute("InRound") ~= true then
		followNextPlayer()
		return
	end

	local character = followedPlayer.Character
	local head = if character then character:FindFirstChild("Head") else nil
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if not head or not head:IsA("BasePart") or not humanoid then
		return
	end

	if firstPerson then
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = head.CFrame * CFrame.new(0, 0.15, -0.25)
	else
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = humanoid
	end
end)

updateSpectatorVisibility()
