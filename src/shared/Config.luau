--!strict
return table.freeze({
	Version = "0.2.0-playtest",
	Arena = {
		Center = Vector3.new(0, 42, 0), Radius = 30, TileSize = 10,
		MaxTilt = 26, Response = 30, AngularSpeed = 3.8, TiltPerStud = 0.9,
		LobbyRadius = 76, VoidY = 12,
	},
	Round = { Intermission = 12, Countdown = 3, Duration = 85, Results = 5, MaxPlayers = 16 },
	Combat = { Range = 9, Cooldown = 0.85, Power = 60, Lift = 15, Recovery = 0.38,
		GrabRange = 7, GrabCooldown = 3.5 },
	Slabs = { Grace = 7, DurabilityMin = 25, DurabilityMax = 37, WarningTime = 1.25 },
	Maps = {
		{ Id = "Coliseum", Name = "Roman Coliseum", Tag = "CRUMBLING STONE", Duration = 85,
			Material = Enum.Material.Slate, Color = Color3.fromRGB(148, 132, 110),
			Accent = Color3.fromRGB(243, 187, 89), Wave = 1.8 },
		{ Id = "Amazon", Name = "Amazon Rapids", Tag = "RAFT • BOWS • FAST", Duration = 65,
			Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(119, 79, 43),
			Accent = Color3.fromRGB(74, 223, 161), Wave = 5.5 },
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
