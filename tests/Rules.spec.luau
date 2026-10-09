--!strict
local Rules=require("../src/shared/Rules")
local checks=0
local function check(condition: boolean, message: string)
	checks+=1; assert(condition,message)
end
check(Rules.teamSize("FFA") == 1,"FFA size")
check(Rules.teamSize("Duos") == 2,"Duos size")
check(Rules.teamSize("Squads") == 4,"Squads size")
check(Rules.teamSize("Unknown") == 1,"Unknown mode fallback")
for i=1,16 do
	check(Rules.teamFor(i,1) == i,"Distinct FFA teams")
	check(Rules.teamFor(i,2) == math.ceil(i/2),"Duos grouping")
	check(Rules.teamFor(i,4) == math.ceil(i/4),"Squads grouping")
end
check(not Rules.shouldEnd({1},1),"Solo practice must not auto-win")
check(Rules.shouldEnd({},1),"Solo elimination ends round")
check(not Rules.shouldEnd({1,2},2),"Opponents still alive")
check(Rules.shouldEnd({1},2),"Last opponent wins")
check(Rules.shouldEnd({2,2,2},4),"Surviving squad wins")
check(not Rules.shouldEnd({1,1,2},2),"Both teams survive")
check(Rules.shouldEnd({},4),"Simultaneous wipe ends round")
check(Rules.validNumber(1),"Normal number accepted")
check(not Rules.validNumber(0/0),"NaN rejected")
check(not Rules.validNumber(math.huge),"Infinity rejected")
check(not Rules.validNumber(-math.huge),"Negative infinity rejected")
check(not Rules.validNumber("1"),"String rejected")
check(not Rules.validNumber(nil),"Nil rejected")
check(not Rules.validNumber(1e9),"Extreme number rejected")
local x,z=Rules.limitTilt(3,4,26)
check(x == 3 and z == 4,"Small tilt preserved")
local cx,cz=Rules.limitTilt(100,-100,26)
check(math.abs(math.sqrt(cx*cx+cz*cz)-26) < 1e-8,"Tilt capped radially")
local zx,zz=Rules.limitTilt(0,0,26)
check(zx == 0 and zz == 0,"Zero tilt stays finite")
check(Rules.stressRate(3,1,10,85) > Rules.stressRate(1,1,10,85),"Crowding increases stress")
check(Rules.stressRate(1,1,10,85) > Rules.stressRate(1,0,10,85),"Tilt increases stress")
check(Rules.stressRate(0,0,80,85) > Rules.stressRate(0,0,10,85),"Late game collapses even empty slabs")
for _,duration in {65,85} do
	local stress=0; local breakAt=0
	for tick=1,duration*60 do
		local age=tick/60
		if age > 7 then stress+=Rules.stressRate(0,0,age,duration)/60 end
		if stress >= 37 then breakAt=age; break end
	end
	check(breakAt > 7 and breakAt < duration,"Empty slabs force a finish before timer expires")
end
for _,bad in {0,4,-1,1.5,math.huge,-math.huge,0/0,"1",false} do
	check(not Rules.validSlot(bad),"Malformed inventory selection rejected")
end
for slot=1,3 do check(Rules.validSlot(slot),"Three valid inventory indices") end
check(Rules.balanceMoment(0,8,20,175)==0,"Balanced crowd causes no directional tilt")
local early=Rules.balanceMoment(8*90,8,10,175)*.16
local late=Rules.balanceMoment(8*90,8,160,175)*.16
check(early<7,"Crowd on one side does not saturate tilt early")
check(late>early and late<26,"Danger grows gradually within the tilt limit")
local function responseAt(fps:number):number
	local value=0
	for _=1,fps*3 do value=Rules.approach(value,15,1.3,1/fps) end
	return value
end
check(math.abs(responseAt(30)-responseAt(144))<1e-6,"Balance smoothing is frame-rate independent")
local idleStress=0
local occupiedStress=0
local idleBreak=0
for tick=1,1750 do
	local age=tick/10
	if age>14 then
		idleStress+=Rules.stressRate(0,.2,age,175)*.1
		occupiedStress+=Rules.stressRate(1,.2,age,175)*.1
	end
	if idleStress>=52 and idleBreak==0 then idleBreak=age end
	if age==60 then check(idleStress<15,"Opening does not destroy empty slabs") end
end
check(idleBreak>100 and idleBreak<175,"Final-minute pressure closes empty safe areas")
check(occupiedStress>idleStress,"Remaining on one stone wears it faster")
-- Impacts remain directional and bounded, including exact-center strikes.
for angle=0,355,5 do
 local a=math.rad(angle)
 local p,r=Rules.impactKick(math.cos(a)*100,math.sin(a)*100,110,8)
 check(math.abs(math.sqrt(p*p+r*r)-8)<1e-6,"Outer meteor reaches configured kick")
 local cp,cr=Rules.limitTilt(25+p,25+r,26)
 check(math.sqrt(cp*cp+cr*cr)<=26.000001,"Combined balance and impact remain capped")
end
local ip,ir=Rules.impactKick(0,0,110,8)
check(ip==ip and ir==ir and ip>0,"Center strike is finite and perceptible")
check(not Rules.inPickupBand(0,0,110,.32,.65),"Exact center has no pickup")
check(Rules.inPickupBand(40,0,110,.32,.65),"Inner contested ring accepts pickup")
check(not Rules.inPickupBand(85,0,110,.32,.65),"Outer rim has no pickup")
local function decayAt(multiplier:number):number
 local stress=0
 for tick=1,1750 do
  local age=tick/10
  if age>10 then stress+=Rules.stressRate(1,.2,age,175)*.1*multiplier end
  if stress>=52 then return age end
 end
 return 175
end
check(decayAt(2.5)<decayAt(1)*.6,"Occupied stone fails substantially sooner")
local impact=8
for _=1,180 do impact=Rules.approach(impact,0,1.5,1/60) end
check(impact<.1,"Meteor tilt settles rather than accumulating forever")
print("PASS: "..checks.." rule assertions")
