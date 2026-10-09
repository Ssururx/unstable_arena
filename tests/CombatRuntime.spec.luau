-- Executed through run_engine_checks.py inside a minimal Roblox stand-in.

local checks=0
local function check(ok,message) checks+=1; assert(ok,message) end
local Config=require("Config")
local U=require("Util")
local events={}; local queued={}
task={delay=function(delay,fn) table.insert(queued,{delay=delay,fn=fn}) end}
local fx={FireAllClients=function(_,kind,a,b) table.insert(events,{kind,a,b}) end,FireClient=function() end}
local arena=require("ArenaService").new(fx); arena:Build(Config.Maps[1],31415)
local active=true
local round={roundId=1,phase="Live",IsActive=function() return active end,Active=function() return {} end}
local targets=0
local combat={Ready=function() return true end,Target=function() targets+=1; return nil end,Aim=function(_,_,aim) return aim end}
local items=require("ItemService").new(round,arena,combat,fx)
local p=Instance.new("Player"); p.Parent=arena.world
local char=Instance.new("Model"); char.Parent=arena.world; p.Character=char
local root=Instance.new("Part"); root.Name="HumanoidRootPart"; root.Parent=char; root.Anchored=false
local hum=Instance.new("Humanoid"); hum.Parent=char; hum.PlatformStand=false
for _,name in {"RightHand","LeftHand"} do local hand=Instance.new("Part"); hand.Name=name; hand.Parent=char end
local Stamina=require("Stamina")
Stamina.reset(p)
p:SetAttribute("Inventory1","Mace"); p:SetAttribute("Inventory1Uses",1); p:SetAttribute("ActiveSlot",1)
local ground=arena.slabs[1]
arena.GroundAt=function() return ground,Vector3.zero end
items:Use(p,Vector3.zAxis)
check(p:GetAttribute("ItemActionKind")=="Mace","Mace starts without nearby target")
check(targets==0,"Target query occurs at contact, not before the animation")
check(p:GetAttribute("Stamina")==76,"Heavy attack consumes stamina")
check(p:GetAttribute("Inventory1")=="Mace" and p:GetAttribute("Inventory1Uses")==1,"Mace remains permanent")
check(#queued==1 and queued[1].delay==Config.Combat.MaceHitTime,"Strike timing matches clip")
queued[1].fn(); table.clear(queued)
check(targets==1 and ground.stress==3.5,"Miss contacts ground and adds bounded stress")
local impact=false; for _,event in events do if event[1]=="MaceImpact" then impact=true end end
check(impact,"Ground impact broadcasts without victim")
local untilTime=p:GetAttribute("ItemActionUntil")
workspace._now=2; p:SetAttribute("Stamina",0)
items:Use(p,Vector3.zAxis)
check(p:GetAttribute("ItemActionUntil")==untilTime and #queued==0,"Exhaustion rejects attack")
Stamina.reset(p); p:SetAttribute("Sprinting",true)
Stamina.step(p,7,true)
check(p:GetAttribute("Stamina")==0 and not p:GetAttribute("Sprinting"),"Sprint exhausts and stops")
Stamina.step(p,.2,false)
check(p:GetAttribute("Stamina")==0,"Regen delay prevents immediate recovery")
workspace._now=3; Stamina.step(p,1,false)
check(p:GetAttribute("Stamina")==21,"Stamina regenerates")
check(not Stamina.spend(p,24) and p:GetAttribute("Stamina")==21,"Rejected spend does not go negative")
workspace._now=5; Stamina.step(p,30,false)
check(p:GetAttribute("Stamina")==100,"Recovery caps at maximum")
items:Clear(p); p:SetAttribute("Inventory1","Sword"); p:SetAttribute("Inventory1Uses",1)
items:Use(p,Vector3.zAxis)
check(p:GetAttribute("ItemActionKind")=="Sword" and #queued==1,"Sword swings without victim")
for _=1,25 do items:Consume(p,1) end
check(p:GetAttribute("Inventory1")=="Sword","Repeated swings do not consume sword")
active=false; queued[1].fn(); table.clear(queued)
check(targets==1,"Elimination cancels pending contact")
active=true; items:Clear(p)
p:SetAttribute("Inventory1","Bow"); p:SetAttribute("Inventory1Uses",3); items:SyncActive(p)
for _=1,3 do items:Consume(p,1) end
check(p:GetAttribute("Inventory1")==nil,"Bow still depletes")
-- Verify distribution on the real generated slab layout.
for _=1,12 do items:Spawn() end
local occupied={}
for _,slab in arena.slabs do if slab.pickup then table.insert(occupied,slab) end end
check(#occupied>=6 and #occupied<=8,"Enough spaced central pickups")
local rules=require("Rules")
for i,slab in occupied do
 local c=slab.cell.center
 check(rules.inPickupBand(c.x,c.z,110,.32,.65),"Pickup stays inside annulus")
 for j=i+1,#occupied do
  local other=occupied[j].cell.center
  check(math.sqrt((c.x-other.x)^2+(c.z-other.z)^2)>=22,"No clumped pickup pairs")
 end
end
-- An impact must break the supplied slab exactly once, even if another lies nearby.
local broken=0; local kicked=0
arena.Break=function(_,slab) check(slab==ground,"Exact target tile fractures"); slab.broken=true; broken+=1 end
arena.MeteorImpulse=function() kicked+=1 end
ground.broken=false
local hazards=require("HazardService").new(round,arena,combat,fx)
hazards:ImpactMeteor(Vector3.zero,ground)
hazards:ImpactMeteor(Vector3.zero,ground)
check(broken==1 and kicked==1,"Destroyed targets cannot generate duplicate impacts")
print("PASS: "..checks.." mocked combat, stamina, impact and pickup checks")
