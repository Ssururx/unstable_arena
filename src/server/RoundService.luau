--!nonstrict
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Shared=game:GetService("ReplicatedStorage").Shared
local Config=require(Shared.Config)
local Rules=require(Shared.Rules)
local U=require(script.Parent.Util)
local Round={}; Round.__index=Round
function Round.new(arena,state,fx)
	return setmetatable({arena=arena,state=state,fx=fx,phase="Waiting",alive={},roster={},votes={},roundId=0,padDwell={}},Round)
end
function Round:IsActive(actor)
	return self.phase=="Live" and self.alive[actor]==true and actor.Parent~=nil and U.root(actor)~=nil
end
function Round:Active()
	local list={}
	for actor in self.alive do if self:IsActive(actor) then table.insert(list,actor) end end
	return list
end
function Round:SetPhase(phase,duration,message)
	self.phase=phase
	workspace:SetAttribute("EndsAt",workspace:GetServerTimeNow()+duration)
	workspace:SetAttribute("Message",message or "")
	workspace:SetAttribute("Phase",phase)
	self:Broadcast()
end
function Round:Broadcast()
	local counts={map=table.create(#Config.Maps,0),mode=table.create(#Config.Modes,0)}
	for p,vote in self.votes do
		if p.Parent==Players then
			if vote.map then counts.map[vote.map]+=1 end
			if vote.mode then counts.mode[vote.mode]+=1 end
		end
	end
	self.arena:SetPadPhase(self.phase,counts)
	self.state:FireAllClients({maps=counts.map,modes=counts.mode})
end
function Round:SelectPads(kind,duration)
	self.padDwell={}
	self:SetPhase(if kind=="map" then "MapVote" else "ModeVote",duration,
		if kind=="map" then "Choose an arena in the courtyard" else "Choose a mode on the courtyard stones")
	local finish=os.clock()+duration
	while os.clock()<finish do
		for _,p in Players:GetPlayers() do
			local root=U.root(p); local index=root and self.arena:PadAt(root.Position,kind)
			local dwell=self.padDwell[p]
			if not index then self.padDwell[p]=nil
			elseif not dwell or dwell.index~=index then self.padDwell[p]={index=index,since=os.clock()}
			elseif os.clock()-dwell.since>=.6 then
				self.votes[p]=self.votes[p] or {}
				if self.votes[p][kind]~=index then
					self.votes[p][kind]=index; p:SetAttribute("Selected"..kind,index); self:Broadcast()
				end
			end
		end
		task.wait(.15)
	end
end
function Round:WinnerVote(kind,count)
	local totals=table.create(count,0)
	for p,vote in self.votes do if p.Parent==Players and vote[kind] then totals[vote[kind]]+=1 end end
	local best=-1; local tied={}
	for index,n in totals do
		if n>best then best=n; tied={index} elseif n==best then table.insert(tied,index) end
	end
	-- Quiet defaults: choosing a pad is optional, with no modal blocking play.
	return if best<=0 then 1 else tied[math.random(#tied)]
end
function Round:Award(actor,name,amount)
	if not actor:IsA("Player") then return end
	local stats=actor:FindFirstChild("leaderstats"); local value=stats and stats:FindFirstChild(name)
	if value then value.Value+=amount end
end
function Round:Eliminate(actor,reason)
	if not self.alive[actor] then return end
	self.alive[actor]=nil; actor:SetAttribute("InRound",false)
	local char=U.character(actor)
	local highlight=char and char:FindFirstChild("ArenaTeam"); if highlight then highlight:Destroy() end
	local root=U.root(actor); if root then root.Anchored=false end
	self.items:Clear(actor)
	local credit=self.combat.credit[actor]
	if credit and os.clock()-credit.time<8 and credit.player.Parent then
		self:Award(credit.player,"KOs",1); self:Award(credit.player,"Coins",5)
	end
	self.combat.credit[actor]=nil
	if actor:IsA("Player") and actor.Parent==Players then
		U.notify(self.fx,actor,"Toast",reason or "ELIMINATED")
		if root then
			root.AssemblyLinearVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero
			char:PivotTo(self.arena:LobbyCFrame(actor.UserId%5))
		end
	elseif char then
		-- Dead NPCs never respawn into the same match or keep fighting.
		local hum=char:FindFirstChildOfClass("Humanoid"); if hum then hum:Move(Vector3.zero) end
		task.delay(1.5,function() if char.Parent then char:Destroy() end end)
	end
end
function Round:AddPlayer(p)
	p:SetAttribute("InRound",false)
	local stats=Instance.new("Folder"); stats.Name="leaderstats"; stats.Parent=p
	for _,name in {"Wins","KOs","Coins"} do local value=Instance.new("IntValue"); value.Name=name; value.Parent=stats end
	local function characterAdded(char)
		local root=char:WaitForChild("HumanoidRootPart",10); local hum=char:WaitForChild("Humanoid",10)
		if not root or not hum or p.Character~=char then return end
		if self.alive[p] then self:Eliminate(p,"ELIMINATED") end
		root.Anchored=false; char:PivotTo(self.arena:LobbyCFrame(p.UserId%5))
		hum.WalkSpeed=20; hum.UseJumpPower=true; hum.JumpPower=45
		local force=char:FindFirstChildOfClass("ForceField"); if force then force:Destroy() end
		hum.Died:Connect(function() if p.Character==char then self:Eliminate(p,"ELIMINATED") end end)
	end
	p.CharacterAdded:Connect(characterAdded)
	if p.Character then task.spawn(characterAdded,p.Character) end
end
function Round:RemovePlayer(p)
	self:Eliminate(p); self.votes[p]=nil; self.padDwell[p]=nil; self.combat:Forget(p)
end
function Round:Cleanup()
	if self.bots then self.bots:Clear() end
	for _,p in Players:GetPlayers() do
		p:SetAttribute("InRound",false); p:SetAttribute("TeamId",nil)
		p:SetAttribute("Selectedmap",nil); p:SetAttribute("Selectedmode",nil)
		local root,hum=U.root(p)
		if root then
			root.Anchored=false; hum.PlatformStand=false; hum.AutoRotate=true
			root.AssemblyLinearVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero
			p.Character:PivotTo(self.arena:LobbyCFrame(p.UserId%5))
			local highlight=p.Character:FindFirstChild("ArenaTeam"); if highlight then highlight:Destroy() end
		end
	end
	self.alive={}; self.roster={}; self.votes={}; self.padDwell={}
	self.items:Reset(); self.arena:Stop(); workspace:SetAttribute("Remaining",0); workspace:SetAttribute("BotCount",0)
end
function Round:Cycle()
	self:Cleanup()
	while #Players:GetPlayers()==0 do self:SetPhase("Waiting",0,"Explore the Coliseum"); task.wait(1) end
	-- Prepare the complete arena before the map-to-mode transition.
	if not self.arena.model then self.arena:Build(Config.Maps[1],31415) end
	self:SelectPads("map",Config.Round.MapVote)
	local map=Config.Maps[self:WinnerVote("map",#Config.Maps)]
	self.roundId+=1; self.arena:Build(map,31415+self.roundId*71)
	workspace:SetAttribute("MapName",map.Name); workspace:SetAttribute("RoundId",self.roundId)
	self:SelectPads("mode",Config.Round.ModeVote)
	local mode=Config.Modes[self:WinnerVote("mode",#Config.Modes)]
	local humans={}
	for _,p in Players:GetPlayers() do if U.root(p) then table.insert(humans,p) end end
	if #humans==0 then return end
	for i=#humans,2,-1 do local j=math.random(i); humans[i],humans[j]=humans[j],humans[i] end
	while #humans>Config.Round.MaxPlayers do table.remove(humans) end
	local roster=table.clone(humans)
	local botCount=Rules.botCount(#humans,mode,Config.Bots.FillTo,Config.Bots.Maximum)
	for i=1,botCount do table.insert(roster,self.bots:Create(i)) end
	if #roster<=Rules.teamSize(mode) then mode="FFA" end
	self.roster=roster; self.initialTeams=math.ceil(#roster/Rules.teamSize(mode))
	workspace:SetAttribute("BotCount",botCount); workspace:SetAttribute("Mode",mode)
	local points=self.arena:SpawnPoints(#roster)
	for i,actor in roster do
		local root,hum=U.root(actor)
		if not root then continue end
		local team=Rules.teamFor(i,Rules.teamSize(mode))
		actor:SetAttribute("TeamId",team); actor:SetAttribute("InRound",true)
		self.alive[actor]=true; self.combat.credit[actor]=nil; self.items:Clear(actor)
		hum.PlatformStand=false; root.AssemblyLinearVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero
		local char=U.character(actor); char:PivotTo(points[i]); root.Anchored=true
		if mode~="FFA" then
			local highlight=Instance.new("Highlight"); highlight.Name="ArenaTeam"; highlight.FillTransparency=1
			highlight.OutlineTransparency=.3; highlight.OutlineColor=Config.TeamColors[(team-1)%#Config.TeamColors+1]
			highlight.DepthMode=Enum.HighlightDepthMode.Occluded; highlight.Parent=char
		end
	end
	workspace:SetAttribute("Remaining",#roster); self:SetPhase("Countdown",Config.Round.Countdown,"GET READY")
	task.wait(Config.Round.Countdown)
	for actor in self.alive do
		local root=U.root(actor)
		if root then root.Anchored=false; if actor:GetAttribute("Bot") then root:SetNetworkOwner(nil) end end
	end
	self.arena:Start(); self:SetPhase("Live",map.Duration,"")
	for _=1,3 do self.items:Spawn() end
	local finish=workspace:GetServerTimeNow()+map.Duration
	while workspace:GetServerTimeNow()<finish and #Players:GetPlayers()>0 do
		local dt=RunService.Heartbeat:Wait()
		for actor in self.alive do
			local root=U.root(actor)
			if not root or root.Position.Y<Config.Arena.VoidY or Vector3.new(root.Position.X,0,root.Position.Z).Magnitude>Config.Arena.EliminationRadius then self:Eliminate(actor) end
		end
		local active=self:Active(); local teams={}
		for _,actor in active do table.insert(teams,actor:GetAttribute("TeamId")) end
		workspace:SetAttribute("Remaining",#active)
		if Rules.shouldEnd(teams,self.initialTeams) then break end
		self.arena:Step(math.min(dt,.1),active); self.items:Step(dt); self.bots:Step()
	end
	local survivors=self:Active(); local team=nil; local tied=false
	for _,actor in survivors do
		local id=actor:GetAttribute("TeamId"); if team and team~=id then tied=true end; team=id
	end
	local message="NO SURVIVORS"
	if tied then message="TIME UP · DRAW"
	elseif team then
		local names={}
		for _,actor in self.roster do
			if actor.Parent and actor:GetAttribute("TeamId")==team then
				table.insert(names,U.name(actor)); self:Award(actor,"Wins",1); self:Award(actor,"Coins",30)
			end
		end
		message=if mode=="FFA" then table.concat(names,", ").." WINS" else "TEAM "..team.." WINS"
	end
	for _,p in humans do if p.Parent==Players then self:Award(p,"Coins",5) end end
	self:SetPhase("Results",Config.Round.Results,message); self.arena:Stop()
	for actor in self.alive do local root=U.root(actor); if root then root.Anchored=true end end
	task.wait(Config.Round.Results)
end
function Round:Run()
	while true do
		local ok,err=xpcall(function() self:Cycle() end,debug.traceback)
		if not ok then
			warn("[UnstableArena] Round failed: "..tostring(err))
			self:SetPhase("Waiting",5,"Arena resetting"); self:Cleanup(); task.wait(5)
		end
	end
end
return Round
