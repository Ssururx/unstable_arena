--!nonstrict
local Util = {}
function Util.character(subject)
	return if subject:IsA("Player") then subject.Character else subject
end
function Util.name(subject)
	return if subject:IsA("Player") then subject.DisplayName else (subject:GetAttribute("DisplayName") or subject.Name)
end
function Util.notify(remote,subject,...)
	if subject:IsA("Player") and subject.Parent then remote:FireClient(subject,...) end
end
function Util.part(parent, name, size, cf, color, material)
	local p = Instance.new("Part")
	p.Name = name; p.Size = size; p.CFrame = cf; p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.Color = color or Color3.fromRGB(114, 109, 99)
	p.Material = material or Enum.Material.Slate
	p.Parent = parent
	return p
end
function Util.weld(a, b)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a; w.Part1 = b; w.Parent = b; b.Anchored = false
	return w
end
function Util.root(subject)
	local model = Util.character(subject)
	if not model then return nil, nil end
	local root = model:FindFirstChild("HumanoidRootPart")
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not hum or hum.Health <= 0 then return nil, nil end
	return root, hum
end
function Util.label(part, text, color)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(170, 42); gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.MaxDistance = 75; gui.AlwaysOnTop = false; gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1); label.BackgroundTransparency = 1
	label.Text = text; label.Font = Enum.Font.GothamBold; label.TextSize = 15
	label.TextColor3 = color or Color3.new(1, 1, 1); label.TextStrokeTransparency = 0.4
	label.Parent = gui
	return label
end
return Util
