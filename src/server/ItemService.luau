--!nonstrict
local Players=game:GetService("Players")
local Debris=game:GetService("Debris")
local Config=require(game:GetService("ReplicatedStorage").Shared.Config)
local U=require(script.Parent.Util)
local Visuals=require(script.Parent.ItemVisuals)
local Items={}; Items.__index=Items

local SLOT_COUNT=3
local function itemAttr(i) return "Inventory"..i end
local function usesAttr(i) return "Inventory"..i.."Uses" end

function Items.new(round,arena,combat,fx)
	return setmetatable({
		round=round,arena=arena,combat=combat,fx=fx,
		arrows={},maces={},nextSpawn=0,
	},Items)
end

function Items:UpdateHeld(p)
	local char=U.character(p); if not char then return end
	local old=char:FindFirstChild("HeldArenaItem"); if old then old:Destroy() end
	local slot=math.clamp(tonumber(p:GetAttribute("ActiveSlot")) or 1,1,SLOT_COUNT)
	local id=p:GetAttribute(itemAttr(slot)); if not id then return end
	local hand=char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm") or char:FindFirstChild("RightLowerArm")
	if not hand or not hand:IsA("BasePart") then return end
	local holder=U.part(char,"HeldArenaItem",Vector3.new(.18,.18,.18),hand.CFrame*CFrame.new(0,-.7,-.2)*CFrame.Angles(0,0,-.18))
	holder.Transparency=1; holder.CanCollide=false; holder.CanQuery=false; holder.CanTouch=false; holder.Massless=true
	U.weld(hand,holder); Visuals.attach(holder,id)
end

function Items:SyncActive(p)
	local slot=math.clamp(tonumber(p:GetAttribute("ActiveSlot")) or 1,1,SLOT_COUNT)
	p:SetAttribute("ActiveSlot",slot)
	p:SetAttribute("Item",p:GetAttribute(itemAttr(slot)))
	p:SetAttribute("ItemUses",p:GetAttribute(usesAttr(slot)) or 0)
	self:UpdateHeld(p)
end

function Items:Select(p,slot)
	if typeof(slot)~="number" then return end
	slot=math.floor(slot)
	if slot<1 or slot>SLOT_COUNT then return end
	p:SetAttribute("ActiveSlot",slot)
	self:SyncActive(p)
end

function Items:FirstEmpty(p)
	for i=1,SLOT_COUNT do
		if not p:GetAttribute(itemAttr(i)) then return i end
	end
	return nil
end

function Items:FirstOccupied(p)
	for i=1,SLOT_COUNT do
		if p:GetAttribute(itemAttr(i)) then return i end
	end
	return nil
end

function Items:Clear(p)
	for i=1,SLOT_COUNT do
		p:SetAttribute(itemAttr(i),nil)
		p:SetAttribute(usesAttr(i),0)
	end
	p:SetAttribute("ActiveSlot",1)
	p:SetAttribute("Item",nil); p:SetAttribute("ItemUses",0)
	p:SetAttribute("ShieldUntil",0); p:SetAttribute("AnchorUntil",0)
	p:SetAttribute("ItemActionUntil",0); p:SetAttribute("ItemActionKind",nil)
	local char=U.character(p)
	if char then
		local shield=char:FindFirstChild("ArenaShield"); if shield then shield:Destroy() end
		local held=char:FindFirstChild("HeldArenaItem"); if held then held:Destroy() end
	end
end

function Items:Reset()
	self.arrows={}; self.maces={}; self.nextSpawn=0
	for _,p in Players:GetPlayers() do self:Clear(p) end
end

function Items:Pickup(p,slab,pickup,id)
	if not self.round:IsActive(p) or slab.broken or slab.pickup~=pickup then return end
	local slot=self:FirstEmpty(p)
	if not slot then U.notify(self.fx,p,"Toast","INVENTORY FULL · use or switch an item"); return end
	local root=U.root(p)
	if not root or not pickup.Parent or (root.Position-pickup.Position).Magnitude>11 then return end
	local ray=RaycastParams.new(); ray.FilterType=Enum.RaycastFilterType.Exclude
	ray.FilterDescendantsInstances={U.character(p),pickup}
	if workspace:Raycast(root.Position,pickup.Position-root.Position,ray) then return end

	slab.pickup=nil; pickup:Destroy()
	p:SetAttribute("PickupUntil",workspace:GetServerTimeNow()+.42)
	p:SetAttribute(itemAttr(slot),id)
	p:SetAttribute(usesAttr(slot),Config.Items[id].Uses)
	if not p:GetAttribute("Item") then p:SetAttribute("ActiveSlot",slot) end
	self:SyncActive(p)
	U.notify(self.fx,p,"Toast",Config.Items[id].Name.." → SLOT "..slot)
end

function Items:Spawn()
	local choices={}; local count=0
	for _,slab in self.arena.slabs do
		if slab.pickup and slab.pickup.Parent then count+=1 end
		if not slab.broken and not slab.pickup and slab.stress<slab.durability*.67 then table.insert(choices,slab) end
	end
	if count>=8 or #choices==0 then return end
	local slab=choices[math.random(#choices)]
	local ids={"Sword","Sword","Mace","Shield","Shield","Anchor","Ram","Brace","Weight","Bow","Bow"}
	local id=ids[math.random(#ids)]; local def=Config.Items[id]
	local pickup=U.part(slab.model,"Pickup_"..id,Vector3.new(1.6,1.2,1.6),slab.part.CFrame*CFrame.new(0,3.8,0),def.Color,Enum.Material.Metal)
	pickup.Transparency=1; Visuals.attach(pickup,id)
	pickup:SetAttribute("ItemId",id)
	pickup.CanCollide=false; pickup.CanQuery=false; pickup.Massless=true
	U.weld(slab.part,pickup)
	local pickupLabel=U.label(pickup,def.Name,Color3.fromRGB(239,221,185)); pickupLabel.Parent.MaxDistance=24
	local prompt=Instance.new("ProximityPrompt")
	prompt.ActionText="Take"; prompt.ObjectText=def.Name; prompt.HoldDuration=.12
	prompt.KeyboardKeyCode=Enum.KeyCode.R; prompt.GamepadKeyCode=Enum.KeyCode.ButtonY
	prompt.MaxActivationDistance=9; prompt.RequiresLineOfSight=true; prompt.Parent=pickup
	slab.pickup=pickup
	prompt.Triggered:Connect(function(actor) self:Pickup(actor,slab,pickup,id) end)
end

function Items:Consume(p,amount)
	local slot=math.clamp(tonumber(p:GetAttribute("ActiveSlot")) or 1,1,SLOT_COUNT)
	local left=math.max(0,(p:GetAttribute(usesAttr(slot)) or 1)-(amount or 1))
	p:SetAttribute(usesAttr(slot),left)
	if left<=0 then
		p:SetAttribute(itemAttr(slot),nil)
		local nextSlot=self:FirstOccupied(p)
		if nextSlot then p:SetAttribute("ActiveSlot",nextSlot) end
	end
	self:SyncActive(p)
end

function Items:Use(p,aim)
	if not self.round:IsActive(p) then return end
	self:SyncActive(p)
	local id=p:GetAttribute("Item"); local def=Config.Items[id]
	if not def then return end
	if not self.combat:Ready(p,"Item",.72) then return end
	local root=U.root(p); if not root then return end
	local now=workspace:GetServerTimeNow()

	if id=="Mace" then
		local target=self.combat:Target(p,Config.Combat.MaceLockRange,false)
		if not target then U.notify(self.fx,p,"Toast","NO TARGET IN MACE RANGE"); return end
		local targetRoot=U.root(target); if not targetRoot then return end
		p:SetAttribute("ItemActionUntil",now+.65); p:SetAttribute("ItemActionKind",id)
		self.fx:FireAllClients("DangerCircle",targetRoot.Position,5.5)
		table.insert(self.maces,{
			p=p,target=target,pos=root.Position+root.CFrame.LookVector*2+Vector3.new(0,1.2,0),
			vel=root.CFrame.LookVector*Config.Combat.MaceSpeed,age=0,delay=.32,visualAge=0,
		})
		self:Consume(p,1)
		U.notify(self.fx,p,"Cooldown","UseItem",.72)
		return
	end

	p:SetAttribute("ItemActionUntil",now+.48)
	p:SetAttribute("ItemActionKind",id)
	local consumed=true
	if id=="Sword" then
		local target=self.combat:Target(p,Config.Combat.SwordRange,false)
		self.fx:FireAllClients("SwordSwing",root.Position,root.CFrame.LookVector)
		if target then
			local other=U.root(target)
			if other then
				local delta=other.Position-root.Position
				local flat=Vector3.new(delta.X,0,delta.Z)
				local direction=if flat.Magnitude>.01 then flat.Unit else root.CFrame.LookVector
				self.combat:Knock(target,direction*Config.Combat.SwordPower+Vector3.new(0,9,0),p)
			end
		end
	elseif id=="Shield" then
		p:SetAttribute("ShieldUntil",now+8)
		local char=U.character(p)
		local old=char:FindFirstChild("ArenaShield"); if old then old:Destroy() end
		local force=Instance.new("ForceField"); force.Name="ArenaShield"; force.Visible=false; force.Parent=char
		Debris:AddItem(force,8)
	elseif id=="Anchor" then
		p:SetAttribute("AnchorUntil",now+5)
	elseif id=="Ram" then
		if not self.combat:Push(p,92,true) then consumed=false end
	elseif id=="Brace" or id=="Weight" then
		local slab=self.arena:Under(root)
		if not slab then U.notify(self.fx,p,"Toast","Stand on a slab first"); consumed=false
		elseif id=="Brace" then
			slab.stress=math.max(0,slab.stress-slab.durability*.55); slab.warningAt=nil
		else
			if slab.extraWeight>0 and os.clock()<slab.weightUntil then
				U.notify(self.fx,p,"Toast","This slab already has a weight"); consumed=false
			else
				slab.extraWeight=2.5; slab.weightUntil=os.clock()+8
				local weight=U.part(slab.model,"WeightBlock",Vector3.new(2,2,2),slab.part.CFrame*CFrame.new(2,3.3,2),def.Color,Enum.Material.Metal)
				weight.Massless=true; weight.CanCollide=false; weight.CanQuery=false
				U.weld(slab.part,weight); Debris:AddItem(weight,8)
			end
		end
	elseif id=="Bow" then
		local direction=self.combat:Aim(p,aim); if not direction then consumed=false
		else
			local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances={U.character(p)}
			local origin=root.Position+Vector3.new(0,1,0)
			table.insert(self.arrows,{p=p,pos=origin,vel=direction*140,age=0,params=params,visualFrom=origin,visualAge=0})
		end
	end
	if not consumed then return end
	self.fx:FireAllClients("Item",root.Position,def.Color)
	U.notify(self.fx,p,"Cooldown","UseItem",.72)
	self:Consume(p,1)
end

function Items:Step(dt)
	if self.round.phase~="Live" then return end
	if os.clock()>=self.nextSpawn then
		self.nextSpawn=os.clock()+4.2; self:Spawn()
	end

	for i=#self.arrows,1,-1 do
		local arrow=self.arrows[i]; local remove=false
		local left=math.min(dt,.2)
		while left>0 and not remove do
			local step=math.min(left,1/30); left-=step
			arrow.age+=step; arrow.vel-=Vector3.new(0,30*step,0)
			local delta=arrow.vel*step
			local hit=workspace:Raycast(arrow.pos,delta,arrow.params)
			local finish=if hit then hit.Position else arrow.pos+delta
			arrow.pos=finish; arrow.visualAge+=step
			if arrow.visualAge>=.075 or hit then
				self.fx:FireAllClients("Arrow",arrow.visualFrom,finish)
				arrow.visualFrom=finish; arrow.visualAge=0
			end
			if hit then
				local model=hit.Instance:FindFirstAncestorOfClass("Model")
				local target=model and (Players:GetPlayerFromCharacter(model) or model)
				if target and self.combat:Enemy(arrow.p,target) then
					self.combat:Knock(target,arrow.vel.Unit*61+Vector3.new(0,9,0),arrow.p)
				else
					local slab=self.arena.byPart[hit.Instance]
					if slab and not slab.broken then slab.stress+=4 end
				end
				remove=true
			end
			if arrow.age>2 then remove=true end
		end
		if remove then table.remove(self.arrows,i) end
	end

	for i=#self.maces,1,-1 do
		local mace=self.maces[i]
		local remove=not self.round:IsActive(mace.p)
		mace.age+=dt
		local targetRoot=not remove and U.root(mace.target) or nil
		if not targetRoot or not self.combat:Enemy(mace.p,mace.target) then remove=true end
		if not remove and mace.age>=mace.delay then
			local left=math.min(dt,.15)
			while left>0 and not remove do
				local step=math.min(left,1/40); left-=step
				local desired=targetRoot.Position+Vector3.new(0,1,0)-mace.pos
				if desired.Magnitude<3.1 then
					local attackerRoot=U.root(mace.p)
					local direction=if attackerRoot then (targetRoot.Position-attackerRoot.Position) else desired
					local flat=Vector3.new(direction.X,0,direction.Z)
					self.combat:Knock(mace.target,(if flat.Magnitude>.01 then flat.Unit else Vector3.zAxis)*74+Vector3.new(0,12,0),mace.p)
					self.fx:FireAllClients("MaceImpact",targetRoot.Position)
					remove=true; break
				end
				local desiredVel=desired.Unit*Config.Combat.MaceSpeed
				mace.vel=mace.vel:Lerp(desiredVel,math.clamp(step*6.5,0,.24))
				local from=mace.pos; mace.pos+=mace.vel*step; mace.visualAge+=step
				if mace.visualAge>=.045 then
					self.fx:FireAllClients("Mace",from,mace.pos)
					mace.visualAge=0
				end
				if mace.age>1.25 then remove=true end
			end
		elseif not remove and mace.age>1.25 then remove=true end
		if remove then table.remove(self.maces,i) end
	end
end
return Items
