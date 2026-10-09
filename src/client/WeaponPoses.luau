--!nonstrict
-- Authored attack timelines in anatomical degrees. Grip is relative to the held weapon.
-- Each clip has anticipation, a quick strike/release, follow-through and guard recovery.
local Poses={}
local sword={
	{0, {right={35,-15,18},left={20,0,-20},rightElbow={45,0,0},body={0,-8,0},grip={0,0,-8}}},
	{.24,{right={112,-58,48},left={48,15,-35},rightElbow={75,0,0},body={8,-28,0},grip={-16,0,22}}},
	{.38,{right={90,5,8},left={40,0,-25},rightElbow={12,0,0},body={-7,3,0},grip={12,0,-15}}},
	{.53,{right={64,66,-24},left={25,-12,-30},rightElbow={8,0,0},body={-10,32,0},grip={30,0,-38}}},
	{.72,{right={46,42,-8},left={18,0,-22},rightElbow={36,0,0},body={-3,16,0},grip={10,0,-12}}},
	{1, {right={35,-15,18},left={20,0,-20},rightElbow={45,0,0},body={0,-8,0},grip={0,0,-8}}},
}
local mace={
	{0, {right={38,-15,25},left={25,0,-25},rightElbow={40,0,0},body={0,-8,0},grip={0,0,0}}},
	{.14,{right={125,-40,45},left={55,15,-35},rightElbow={72,0,0},body={8,-24,0},grip={-55,0,30}}},
	{.30,{right={155,-20,20},left={65,0,-30},rightElbow={38,0,0},body={12,-18,0},grip={-115,0,75}}},
	{.38,{right={38,25,10},left={40,0,-25},rightElbow={5,0,0},body={-20,20,0},grip={60,0,-12}}},
	{.62,{right={38,30,8},left={25,0,-32},rightElbow={12,0,0},body={-12,15,0},grip={45,0,-8}}},
	{.80,{right={50,5,22},left={20,0,-24},rightElbow={65,0,0},body={7,-6,0},grip={-35,0,12}}},
	{1, {right={38,-15,25},left={25,0,-25},rightElbow={40,0,0},body={0,-8,0},grip={0,0,0}}},
}
local function pose(angles) return CFrame.Angles(math.rad(angles[1]),math.rad(angles[2]),math.rad(angles[3])) end
function Poses.sample(kind,t,alternate)
	local clip=if kind=="Sword" then sword else mace
	local result={}
	for i=1,#clip-1 do
		local a,b=clip[i],clip[i+1]
		if t>=a[1] and t<=b[1] then
			local alpha=(t-a[1])/(b[1]-a[1])
			alpha=alpha*alpha*(3-2*alpha)
			for role,angles in a[2] do
				local target=b[2][role] or angles
				local from=table.clone(angles); local to=table.clone(target)
				if kind=="Sword" and alternate then from[2]*=-1; from[3]*=-1; to[2]*=-1; to[3]*=-1 end
				result[role]=pose(from):Lerp(pose(to),alpha)
			end
			break
		end
	end
	return result
end
return Poses
