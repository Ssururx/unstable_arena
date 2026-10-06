--!nonstrict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Rules = require(Shared.Rules)
local U = require(script.Parent.Util)
local Round = {}; Round.__index = Round

function Round.new(arena, state, fx)
	return setmetatable({arena=arena,state=state,fx=fx,phase="Waiting",alive={},roster={},votes={},roundId=0},Round)
end
function Round:IsActive(p)
	return self.phase == "Live" and self.alive[p] == true and p.Parent == Players and U.root(p) ~= nil
end
function Round:Active()
	local list = {}
	for p in self.alive do if self:IsActive(p) then table.insert(list,p) end end
	return list
end
function Round:SetPhase(phase, duration, message)
	self.phase = phase
	workspace:SetAttribute("Phase",phase)
	workspace:SetAttribute("EndsAt",workspace:GetServerTimeNow()+duration)
	workspace:SetAttribute("Message",message or "")
	self:Broadcast()
end
function Round:Broadcast()
	local maps = {0,0}; local modes = {0,0,0}
	for p, vote in self.votes do
		if p.Parent == Players then
			if vote.map then maps[vote.map] += 1 end
			if vote.mode then modes[vote.mode] += 1 end
		end
	end
	self.state:FireAllClients({maps=maps,modes=modes})
end
function Round:Vote(p, kind, index)
	if self.phase ~= "Vote" or typeof(index) ~= "number" or index ~= math.floor(index) then return end
	local max = if kind == "map" then #Config.Maps elseif kind == "mode" then #Config.Modes else 0
	if index < 1 or index > max then return end
	self.votes[p] = self.votes[p] or {}; self.votes[p][kind] = index
	self:Broadcast()
end
function Round:WinnerVote(kind, count)
	local totals = table.create(count,0)
	for _, vote in self.votes do if vote[kind] then totals[vote[kind]] += 1 end end
	local best = -1; local tied = {}
	for index, n in totals do
		if n > best then best=n; tied={index} elseif n == best then table.insert(tied,index) end
	end
	return tied[math.random(#tied)]
end
function Round:Award(p, name, amount)
	local stats = p:FindFirstChild("leaderstats"); local value = stats and stats:FindFirstChild(name)
	if value then value.Value += amount end
end
function Round:Eliminate(p, reason)
	if not self.alive[p] then return end
	self.alive[p] = nil; p:SetAttribute("InRound",false)
	local highlight=p.Character and p.Character:FindFirstChild("ArenaTeam"); if highlight then highlight:Destroy() end
	local root = U.root(p); if root then root.Anchored=false end
	if self.items then self.items:Clear(p) end
	if self.combat then
		local credit = self.combat.credit[p]
		if not self.practice and credit and os.clock()-credit.time < 8 and credit.player.Parent == Players then
			self:Award(credit.player,"KOs",1); self:Award(credit.player,"Coins",5)
			self.fx:FireClient(credit.player,"Toast","KNOCKOUT +5 coins")
		end
		self.combat.credit[p] = nil
	end
	if p.Parent == Players then
		self.fx:FireClient(p,"Toast",reason or "ELIMINATED • watch from the stands or spectate")
		if root then
			root.AssemblyLinearVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero
			p.Character:PivotTo(self.arena:LobbyCFrame(p.UserId%5))
		end
	end
end
function Round:AddPlayer(p)
	p:SetAttribute("InRound",false)
	local stats = Instance.new("Folder"); stats.Name="leaderstats"; stats.Parent=p
	for _, name in {"Wins","KOs","Coins"} do
		local value = Instance.new("IntValue"); value.Name=name; value.Parent=stats
	end
	local function characterAdded(char)
		local root = char:WaitForChild("HumanoidRootPart",10)
		local hum = char:WaitForChild("Humanoid",10)
		if not root or not hum or p.Character ~= char then return end
		if self.alive[p] then self:Eliminate(p,"ELIMINATED") end
		root.Anchored=false
		char:PivotTo(self.arena:LobbyCFrame(p.UserId%5))
		hum.WalkSpeed=20; hum.UseJumpPower=true; hum.JumpPower=45
		local force = char:FindFirstChildOfClass("ForceField"); if force then force:Destroy() end
		hum.Died:Connect(function()
			if p.Character == char then self:Eliminate(p,"ELIMINATED • rejoining the stands") end
		end)
	end
	p.CharacterAdded:Connect(characterAdded)
	if p.Character then task.spawn(characterAdded,p.Character) end
end
function Round:RemovePlayer(p)
	self:Eliminate(p,"Left"); self.votes[p]=nil
	if self.combat then self.combat:Forget(p) end
end
function Round:Cleanup()
	for _, p in Players:GetPlayers() do
		p:SetAttribute("InRound",false); p:SetAttribute("TeamId",nil)
		local root, hum = U.root(p)
		if root then
			root.Anchored=false; hum.PlatformStand=false; hum.AutoRotate=true
			root.AssemblyLinearVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero
			p.Character:PivotTo(self.arena:LobbyCFrame(p.UserId%5))
			local highlight = p.Character:FindFirstChild("ArenaTeam"); if highlight then highlight:Destroy() end
		end
	end
	self.alive={}; self.roster={}
	if self.items then self.items:Reset() end
	if self.arena.core and self.arena.core.Parent then self.arena:Stop() end
	workspace:SetAttribute("Remaining",0)
end
function Round:Cycle()
	self:Cleanup(); self.votes={}
	while #Players:GetPlayers() == 0 do self:SetPhase("Waiting",0,"Waiting for players"); task.wait(1) end
	self:SetPhase("Vote",Config.Round.Intermission,"Choose the next arena")
	task.wait(Config.Round.Intermission)
	local map = Config.Maps[self:WinnerVote("map",#Config.Maps)]
	local mode = Config.Modes[self:WinnerVote("mode",#Config.Modes)]
	local roster={}
	for _, p in Players:GetPlayers() do if U.root(p) then table.insert(roster,p) end end
	for i=#roster,2,-1 do local j=math.random(i); roster[i],roster[j]=roster[j],roster[i] end
	while #roster > Config.Round.MaxPlayers do table.remove(roster) end
	if #roster == 0 then return end
	-- Never put the entire server on one team. Uneven final teams are allowed.
	if #roster <= Rules.teamSize(mode) then mode="FFA" end
	self.practice = #roster == 1; self.roundId+=1
	self.arena:Build(map); self.roster=roster
	workspace:SetAttribute("RoundId",self.roundId)
	workspace:SetAttribute("MapName",map.Name)
	workspace:SetAttribute("Mode",if self.practice then "SOLO PRACTICE" else mode)
	local points=self.arena:SpawnPoints(#roster)
	local size=Rules.teamSize(mode)
	self.initialTeams=math.ceil(#roster/size)
	for i,p in roster do
		local root,hum=U.root(p)
		if root then
			local team=Rules.teamFor(i,size)
			p:SetAttribute("TeamId",team); p:SetAttribute("InRound",true)
			self.alive[p]=true; self.combat.credit[p]=nil
			self.items:Clear(p)
			hum.PlatformStand=false
			root.AssemblyLinearVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero
			p.Character:PivotTo(points[i]); root.Anchored=true
			local highlight=Instance.new("Highlight"); highlight.Name="ArenaTeam"
			highlight.FillTransparency=1; highlight.OutlineTransparency=.3
			highlight.OutlineColor=Config.TeamColors[(team-1)%#Config.TeamColors+1]
			highlight.DepthMode=Enum.HighlightDepthMode.Occluded; highlight.Parent=p.Character
			if mode ~= "FFA" then self.fx:FireClient(p,"Toast","TEAM "..team.." • match your outline colors") end
		end
	end
	workspace:SetAttribute("Remaining",#roster)
	self:SetPhase("Countdown",Config.Round.Countdown,"GET READY")
	task.wait(Config.Round.Countdown)
	for p in self.alive do local root=U.root(p); if root then root.Anchored=false end end
	self.arena:Start()
	self:SetPhase("Live",map.Duration,"PUSH • BALANCE • SURVIVE")
	for _=1,3 do self.items:Spawn() end
	local untilTime=workspace:GetServerTimeNow()+map.Duration
	while workspace:GetServerTimeNow() < untilTime do
		local dt=RunService.Heartbeat:Wait()
		for p in self.alive do
			local root=U.root(p)
			if not root or root.Position.Y < Config.Arena.VoidY or (root.Position-Config.Arena.Center).Magnitude > 60 then
				self:Eliminate(p)
			end
		end
		local active=self:Active(); local teams={}
		for _,p in active do table.insert(teams,p:GetAttribute("TeamId")) end
		workspace:SetAttribute("Remaining",#active)
		if Rules.shouldEnd(teams,self.initialTeams) then break end
		self.arena:Step(math.min(dt,.1),active)
		self.items:Step(dt)
	end
	local survivors=self:Active(); local team=nil; local tied=false
	for _,p in survivors do
		local id=p:GetAttribute("TeamId")
		if team and team ~= id then tied=true end
		team=id
	end
	local message="NO SURVIVORS"
	if self.practice then message="PRACTICE COMPLETE • invite a friend to compete"
	elseif tied then message="TIME UP • DRAW"
	elseif team then
		local names={}
		for _,p in self.roster do
			if p.Parent == Players and p:GetAttribute("TeamId") == team then
				table.insert(names,p.DisplayName); self:Award(p,"Wins",1); self:Award(p,"Coins",30)
			end
		end
		message=if mode == "FFA" then table.concat(names,", ").." WINS!" else "TEAM "..team.." WINS!"
	end
	if not self.practice then
		for _,p in self.roster do if p.Parent == Players then self:Award(p,"Coins",5) end end
	end
	self:SetPhase("Results",Config.Round.Results,message)
	self.arena:Stop()
	for p in self.alive do local root=U.root(p); if root then root.Anchored=true end end
	task.wait(Config.Round.Results)
end
function Round:Run()
	while true do
		local ok,err=xpcall(function() self:Cycle() end,debug.traceback)
		if not ok then
			warn("[UnstableArena] Round failed: "..tostring(err))
			self:SetPhase("Waiting",5,"Arena resetting")
			self:Cleanup(); task.wait(5)
		end
	end
end
return Round
