--!strict
-- Engine-independent rules; tested with the standalone Luau runner.
local Rules = {}
function Rules.botCount(humans:number,mode:string,fillTo:number,maximum:number):number
	if humans <= 0 then return 0 end
	local teamSize=if mode=="Squads" then 4 elseif mode=="Duos" then 2 else 1
	return math.clamp(math.max(fillTo,teamSize*2)-humans,0,maximum)
end
function Rules.teamSize(mode: string): number
	return if mode == "Duos" then 2 elseif mode == "Squads" then 4 else 1
end
function Rules.teamFor(index: number, size: number): number
	return math.ceil(index / size)
end
function Rules.shouldEnd(teamIds: { number }, initialTeams: number): boolean
	local unique = {}
	local count = 0
	for _, id in teamIds do
		if not unique[id] then unique[id] = true; count += 1 end
	end
	return count == 0 or (initialTeams > 1 and count <= 1)
end
function Rules.stressRate(weight: number, tilt: number, age: number, duration: number): number
	local urgency = math.clamp((age / duration - 0.48) / 0.52, 0, 1)
	return 0.10 + tilt * 0.25 + weight * 0.85 + math.max(0, weight - 1) * 0.6 + urgency * 5.5
end
function Rules.limitTilt(x: number, z: number, limit: number): (number, number)
	local length = math.sqrt(x * x + z * z)
	if length > limit then return x / length * limit, z / length * limit end
	return x, z
end
function Rules.validNumber(n: any): boolean
	return type(n) == "number" and n == n and math.abs(n) < 1e7
end
return table.freeze(Rules)
