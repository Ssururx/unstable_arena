--!nonstrict
local Config=require(game:GetService("ReplicatedStorage").Shared.Config)
local Stamina={}
function Stamina.reset(actor)
 actor:SetAttribute("Stamina",Config.Stamina.Max)
 actor:SetAttribute("StaminaRegenAt",0)
end
function Stamina.spend(actor,cost)
 local value=actor:GetAttribute("Stamina") or Config.Stamina.Max
 if value<cost then return false end
 actor:SetAttribute("Stamina",math.max(0,value-cost))
 actor:SetAttribute("StaminaRegenAt",workspace:GetServerTimeNow()+Config.Stamina.RegenDelay)
 return true
end
function Stamina.step(actor,dt,moving)
 local value=actor:GetAttribute("Stamina") or Config.Stamina.Max
 local now=workspace:GetServerTimeNow()
 if actor:GetAttribute("Sprinting") and moving then
  value=math.max(0,value-Config.Stamina.SprintDrain*dt)
  actor:SetAttribute("StaminaRegenAt",now+Config.Stamina.RegenDelay)
  if value<=0 then actor:SetAttribute("Sprinting",false) end
 elseif now>=(actor:GetAttribute("StaminaRegenAt") or 0) then
  value=math.min(Config.Stamina.Max,value+Config.Stamina.Regen*dt)
 end
 actor:SetAttribute("Stamina",value)
end
return Stamina
