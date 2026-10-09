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
	return 0.09 + tilt * 0.20 + weight * 0.65 + math.max(0, weight - 1) * 0.45 + urgency * 2.4
end
function Rules.limitTilt(x: number, z: number, limit: number): (number, number)
	local length = math.sqrt(x * x + z * z)
	if length > limit then return x / length * limit, z / length * limit end
	return x, z
end
function Rules.validNumber(n: any): boolean
	return type(n) == "number" and n == n and math.abs(n) < 1e7
end
function Rules.validSlot(value: any): boolean
	return Rules.validNumber(value) and value%1==0 and value>=1 and value<=3
end
-- Ballast prevents a full lobby from multiplying the early tilt to its limit.
function Rules.balanceMoment(moment: number, weight: number, age: number, duration: number): number
	local progress=math.clamp(age/duration,0,1)
	return moment/(4+weight*.6)*(.45+.75*progress)
end
function Rules.approach(current: number, target: number, response: number, dt: number): number
	return current+(target-current)*(1-math.exp(-response*dt))
end
function Rules.impactKick(x:number,z:number,radius:number,strength:number): (number,number)
	local distance=math.sqrt(x*x+z*z)
	if distance<.01 then return strength*.35,0 end
	local amount=strength*math.clamp(distance/(radius*.65),.35,1)
	return z/distance*amount,-x/distance*amount
end
function Rules.inPickupBand(x:number,z:number,radius:number,inner:number,outer:number):boolean
	local d=x*x+z*z
	return d>=(radius*inner)^2 and d<=(radius*outer)^2
end
return table.freeze(Rules)
