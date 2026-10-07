--!nonstrict
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local U = require(script.Parent.Util)
local Visuals=require(script.Parent.ItemVisuals)
local Items = {}; Items.__index = Items

function Items.new(round, arena, combat, fx)
	return setmetatable({round=round, arena=arena, combat=combat, fx=fx, arrows={}, nextSpawn=0},Items)
end
function Items:Clear(p)
	p:SetAttribute("Item",nil); p:SetAttribute("ItemUses",0)
	p:SetAttribute("ShieldUntil",0); p:SetAttribute("AnchorUntil",0)
	local char = U.character(p)
	if char then
		local shield = char:FindFirstChild("ArenaShield"); if shield then shield:Destroy() end
	end
end
function Items:Reset()
	self.arrows = {}; self.nextSpawn = 0
	for _, p in Players:GetPlayers() do self:Clear(p) end
end
function Items:Pickup(p, slab, pickup, id)
	if not self.round:IsActive(p) or p:GetAttribute("Item") or slab.broken or slab.pickup ~= pickup then return end
	local root = U.root(p)
	if not root or not pickup.Parent or (root.Position-pickup.Position).Magnitude > 11 then return end
	-- Prompts are client-triggerable: validate distance, state and visibility on the server.
	local ray = RaycastParams.new(); ray.FilterType = Enum.RaycastFilterType.Exclude
	ray.FilterDescendantsInstances = {U.character(p),pickup}
	if workspace:Raycast(root.Position,pickup.Position-root.Position,ray) then return end
	slab.pickup = nil; pickup:Destroy()
	p:SetAttribute("PickupUntil",workspace:GetServerTimeNow()+.42)
	p:SetAttribute("Item",id); p:SetAttribute("ItemUses",Config.Items[id].Uses)
	U.notify(self.fx,p,"Toast",Config.Items[id].Name)
end
function Items:Spawn()
	local choices = {}
	local count = 0
	for _, slab in self.arena.slabs do
		if slab.pickup and slab.pickup.Parent then count += 1 end
		if not slab.broken and not slab.pickup and slab.stress < slab.durability*.65 then table.insert(choices,slab) end
	end
	if count >= 5 or #choices == 0 then return end
	local slab = choices[math.random(#choices)]
	local ids = {"Shield","Anchor","Ram","Brace","Weight","Bow"}
	local id = ids[math.random(#ids)]; local def = Config.Items[id]
	local pickup = U.part(slab.model,"Pickup_"..id,Vector3.new(1.6,1.2,1.6),slab.part.CFrame*CFrame.new(0,3.8,0),def.Color,Enum.Material.Metal)
	pickup.Transparency=1; Visuals.attach(pickup,id)
	pickup:SetAttribute("ItemId",id)
	pickup.CanCollide = false; pickup.CanQuery = false; pickup.Massless = true
	U.weld(slab.part,pickup)
	local pickupLabel=U.label(pickup,def.Name,Color3.fromRGB(239,221,185)); pickupLabel.Parent.MaxDistance=24
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Take"; prompt.ObjectText = def.Name; prompt.HoldDuration = .12
	prompt.KeyboardKeyCode = Enum.KeyCode.R; prompt.GamepadKeyCode = Enum.KeyCode.ButtonY
	prompt.MaxActivationDistance = 9; prompt.RequiresLineOfSight = true; prompt.Parent = pickup
	slab.pickup = pickup
	prompt.Triggered:Connect(function(p) self:Pickup(p,slab,pickup,id) end)
end
function Items:Use(p, aim)
	if not self.round:IsActive(p) then return end
	local id = p:GetAttribute("Item"); local def = Config.Items[id]
	if not def then return end
	if not self.combat:Ready(p,"Item",.8) then return end
	local root = U.root(p); if not root then return end
	local now = workspace:GetServerTimeNow()
	p:SetAttribute("ItemActionUntil",now+.48)
	p:SetAttribute("ItemActionKind",id)
	if id == "Shield" then
		p:SetAttribute("ShieldUntil",now+8)
		local char=U.character(p)
		local old = char:FindFirstChild("ArenaShield"); if old then old:Destroy() end
		local force = Instance.new("ForceField"); force.Name = "ArenaShield"; force.Parent = char
		Debris:AddItem(force,8)
	elseif id == "Anchor" then
		p:SetAttribute("AnchorUntil",now+5)
	elseif id == "Ram" then
		if not self.combat:Push(p,100,true) then return end
	elseif id == "Brace" or id == "Weight" then
		local slab = self.arena:Under(root)
		if not slab then U.notify(self.fx,p,"Toast","Stand on a slab first"); return end
		if id == "Brace" then
			slab.stress = math.max(0,slab.stress-slab.durability*.65); slab.warningAt = nil
		else
			if slab.extraWeight > 0 and os.clock() < slab.weightUntil then
				U.notify(self.fx,p,"Toast","This slab already has a weight"); return
			end
			slab.extraWeight = 3; slab.weightUntil = os.clock()+8
			local weight = U.part(slab.model,"WeightBlock",Vector3.new(2,2,2),slab.part.CFrame*CFrame.new(2,3.3,2),def.Color,Enum.Material.Metal)
			weight.Massless = true; weight.CanCollide = false; weight.CanQuery = false
			U.weld(slab.part,weight); Debris:AddItem(weight,8)
		end
	elseif id == "Bow" then
		local direction = self.combat:Aim(p,aim); if not direction then return end
		local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {U.character(p)}
		local origin=root.Position+Vector3.new(0,1,0)
		table.insert(self.arrows,{p=p,pos=origin,vel=direction*140,age=0,params=params,visualFrom=origin,visualAge=0})
	end
	self.fx:FireAllClients("Item",root.Position,def.Color)
	U.notify(self.fx,p,"Cooldown","UseItem",.8)
	local remaining = (p:GetAttribute("ItemUses") or 1)-1
	p:SetAttribute("ItemUses",remaining)
	if remaining <= 0 then p:SetAttribute("Item",nil) end
end
function Items:Step(dt)
	if self.round.phase ~= "Live" then return end
	if os.clock() >= self.nextSpawn then
		self.nextSpawn = os.clock()+3.5; self:Spawn()
	end
	for i = #self.arrows,1,-1 do
		local arrow = self.arrows[i]; local remove = false
		local left = math.min(dt,.2)
		while left > 0 and not remove do
			local step = math.min(left,1/30); left -= step
			arrow.age += step; arrow.vel -= Vector3.new(0,30*step,0)
			local delta = arrow.vel*step
			local hit = workspace:Raycast(arrow.pos,delta,arrow.params)
			local finish = if hit then hit.Position else arrow.pos+delta
			arrow.pos = finish
			arrow.visualAge += step
			if arrow.visualAge >= .075 or hit then
				self.fx:FireAllClients("Arrow",arrow.visualFrom,finish)
				arrow.visualFrom=finish; arrow.visualAge=0
			end
			if hit then
				local model = hit.Instance:FindFirstAncestorOfClass("Model")
				local target = model and (Players:GetPlayerFromCharacter(model) or model)
				if target and self.combat:Enemy(arrow.p,target) then
					self.combat:Knock(target,arrow.vel.Unit*65+Vector3.new(0,10,0),arrow.p)
				else
					local slab=self.arena.byPart[hit.Instance]
					if slab and not slab.broken then slab.stress+=5 end
				end
				remove = true
			end
			if arrow.age > 2 then remove = true end
		end
		if remove then table.remove(self.arrows,i) end
	end
end
return Items
