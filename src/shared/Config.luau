--!strict

local Config = {
	Arena = {
		Center = Vector3.new(0, 35, 0),
		GridRadius = 2,
		SlabSize = 11,
		SlabGap = 0.35,
		SlabThickness = 2.2,
		CoreSize = Vector3.new(6, 2, 6),
		PedestalHeight = 28,
		MaxTiltDegrees = 17,
		TiltPerStud = 0.42,
		TiltResponsiveness = 7,
		PositionResponsiveness = 35,
	},
	Slabs = {
		GracePeriod = 10,
		DurabilityMin = 21,
		DurabilityMax = 34,
		BaseStressPerSecond = 0.035,
		PlayerStressPerSecond = 0.72,
		CrowdStressMultiplier = 0.42,
		TiltStressPerSecond = 0.38,
		BreakDownwardSpeed = 7,
		CleanupDelay = 10,
	},
	Push = {
		Cooldown = 1.15,
		Range = 9,
		MinimumFacingDot = 0.25,
		Impulse = 52,
		UpwardImpulse = 13,
		SelfRecoil = 5,
	},
	Round = {
		MinimumPlayers = 1,
		Intermission = 8,
		Countdown = 4,
		Duration = 90,
		VoidDepth = 32,
	},
}

return table.freeze(Config)
