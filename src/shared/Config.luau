--!strict
return table.freeze({
	Version = "0.3.0-coliseum",
	Arena = {
		Center = Vector3.new(0, 58, 0), Radius = 52, SlabCount = 38,
		MaxTilt = 23, Response = 32, AngularSpeed = 3.8, TiltPerStud = 0.42,
		LobbyRadius = 89, VoidY = 18, EliminationRadius = 65,
	},
	Round = { MapVote = 9, ModeVote = 10, Countdown = 3, Duration = 95, Results = 5, MaxPlayers = 16 },
	Bots = { FillTo = 6, Maximum = 7, ThinkInterval = 0.22, WalkSpeed = 17, PushCooldown = 1.65 },
	Combat = { Range = 9, Cooldown = 0.85, Power = 60, Lift = 15, Recovery = 0.38,
		GrabRange = 7, GrabCooldown = 3.5 },
	Slabs = { Grace = 9, DurabilityMin = 32, DurabilityMax = 46, WarningTime = 1.6 },
	Maps = {
		{ Id = "Coliseum", Name = "Roman Coliseum", Tag = "THE FRACTURED ARENA", Duration = 95,
			Material = Enum.Material.Limestone, Color = Color3.fromRGB(151, 139, 116),
			Accent = Color3.fromRGB(190, 146, 74), Wave = 2.4 },
	},
	Modes = { "FFA", "Duos", "Squads" },
	TeamColors = {
		Color3.fromRGB(81, 173, 255), Color3.fromRGB(255, 119, 113),
		Color3.fromRGB(156, 124, 255), Color3.fromRGB(255, 211, 94),
		Color3.fromRGB(86, 226, 174), Color3.fromRGB(255, 137, 211),
		Color3.fromRGB(153, 214, 255), Color3.fromRGB(217, 200, 174),
	},
	Items = {
		Shield = { Name = "Shield", Hint = "Block the next hit for 8s", Uses = 1, Color = Color3.fromRGB(92, 173, 255) },
		Anchor = { Name = "Anchor", Hint = "Resist hits for 5s • adds slab stress", Uses = 1, Color = Color3.fromRGB(170, 171, 194) },
		Ram = { Name = "Ram", Hint = "Power shove • watch the recoil", Uses = 1, Color = Color3.fromRGB(255, 146, 73) },
		Brace = { Name = "Brace Kit", Hint = "Repair the slab under your feet", Uses = 1, Color = Color3.fromRGB(90, 226, 157) },
		Weight = { Name = "Weight Block", Hint = "Load your slab • tip the balance", Uses = 1, Color = Color3.fromRGB(224, 198, 91) },
		Bow = { Name = "Knockback Bow", Hint = "Aim at the crosshair • 3 arrows", Uses = 3, Color = Color3.fromRGB(211, 137, 255) },
	},
})
