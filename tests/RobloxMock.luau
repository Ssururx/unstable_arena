-- Geometry-only Roblox stand-in. It does not simulate physics, replication or rendering.
local M={}
local V={}; V.__index=function(v,k)
	if k=="Magnitude" then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end
	if k=="Unit" then return v/v.Magnitude end
	return V[k]
end
local function v(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},V) end
function V.__add(a,b) return v(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
function V.__sub(a,b) return v(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
function V.__unm(a) return v(-a.X,-a.Y,-a.Z) end
function V.__mul(a,b) if type(a)=="number" then a,b=b,a end; return v(a.X*b,a.Y*b,a.Z*b) end
function V.__div(a,b) return a*(1/b) end
function V:Dot(b) return self.X*b.X+self.Y*b.Y+self.Z*b.Z end
function V:Cross(b) return v(self.Y*b.Z-self.Z*b.Y,self.Z*b.X-self.X*b.Z,self.X*b.Y-self.Y*b.X) end
function V:Lerp(b,t) return self+(b-self)*t end
local Vector3={new=v,zero=v(),one=v(1,1,1),xAxis=v(1,0,0),yAxis=v(0,1,0),zAxis=v(0,0,1)}
local CF={}
CF.__index=function(a,k)
	if k=="Position" then return a.p end
	if k=="LookVector" then return -a.b end
	if k=="RightVector" then return a.r end
	if k=="UpVector" then return a.u end
	return CF[k]
end
local function cf(p,r,u,b) return setmetatable({p=p or v(),r=r or v(1,0,0),u=u or v(0,1,0),b=b or v(0,0,1)},CF) end
function CF:VectorToWorldSpace(q) return self.r*q.X+self.u*q.Y+self.b*q.Z end
function CF:PointToWorldSpace(q) return self.p+self:VectorToWorldSpace(q) end
function CF:PointToObjectSpace(q) local d=q-self.p; return v(d:Dot(self.r),d:Dot(self.u),d:Dot(self.b)) end
function CF:ToObjectSpace(other) return self:Inverse()*other end
function CF:Inverse() return cf(v(-self.p:Dot(self.r),-self.p:Dot(self.u),-self.p:Dot(self.b)),v(self.r.X,self.u.X,self.b.X),v(self.r.Y,self.u.Y,self.b.Y),v(self.r.Z,self.u.Z,self.b.Z)) end
function CF.__mul(a,b)
	if getmetatable(b)==V then return a:PointToWorldSpace(b) end
	return cf(a:PointToWorldSpace(b.p),a:VectorToWorldSpace(b.r),a:VectorToWorldSpace(b.u),a:VectorToWorldSpace(b.b))
end
function CF.__add(a,b) return cf(a.p+b,a.r,a.u,a.b) end
local CFrame={identity=cf(),fromMatrix=cf}
function CFrame.new(x,y,z) return cf(if type(x)=="table" then x else v(x,y,z)) end
function CFrame.Angles(x,y,z)
	local sx,cx,sy,cy,sz,cz=math.sin(x),math.cos(x),math.sin(y),math.cos(y),math.sin(z),math.cos(z)
	return cf(v(),v(1,0,0),v(0,cx,sx),v(0,-sx,cx))*cf(v(),v(cy,0,-sy),v(0,1,0),v(sy,0,cy))*cf(v(),v(cz,sz,0),v(-sz,cz,0),v(0,0,1))
end
function CFrame.lookAt(p,q,up)
	local back=(p-q).Unit; local right=(up or v(0,1,0)):Cross(back).Unit
	return cf(p,right,back:Cross(right),back)
end
local C={}; C.__index=C
local function color(r,g,b) assert(type(r)=="number" and type(g)=="number" and type(b)=="number","Color requires three numbers"); return setmetatable({R=r,G=g,B=b},C) end
function C:Lerp(b,t) return color(self.R+(b.R-self.R)*t,self.G+(b.G-self.G)*t,self.B+(b.B-self.B)*t) end
local Color3={new=color,fromRGB=function(r,g,b) return color(r/255,g/255,b/255) end}
local objects={}
local I={}
local function new(class)
	local o=setmetatable({_props={ClassName=class,Name=class,CFrame=cf(),Size=v(1,1,1),Color=color(.5,.5,.5),Transparency=0,CanCollide=true,Health=100},_children={},_attrs={}},I)
	table.insert(objects,o); return o
end
I.__index=function(o,k)
	if I[k] then return I[k] end
	if k=="Position" then return o._props.CFrame.Position end
	if k=="AssemblyMass" then return 10 end
	if k=="Died" or k=="Triggered" or k=="Activated" then return {Connect=function() end} end
	return o._props[k]
end
I.__newindex=function(o,k,value)
	if k=="Parent" then
		local old=o._props.Parent
		if old then local index=table.find(old._children,o); if index then table.remove(old._children,index) end end
		if value then table.insert(value._children,o) end
	end
	if k=="Position" then o._props.CFrame=cf(value,o.CFrame.r,o.CFrame.u,o.CFrame.b) else o._props[k]=value end
end
function I:IsA(kind) return self.ClassName==kind or (kind=="BasePart" and (self.ClassName=="Part" or self.ClassName=="WedgePart" or self.ClassName=="SpawnLocation")) end
function I:GetChildren() return table.clone(self._children) end
function I:GetDescendants()
	local all={}; for _,child in self._children do table.insert(all,child); for _,d in child:GetDescendants() do table.insert(all,d) end end
	return all
end
function I:FindFirstChild(name) for _,c in self._children do if c.Name==name then return c end end; return nil end
function I:FindFirstChildOfClass(class) for _,c in self._children do if c.ClassName==class then return c end end; return nil end
function I:SetAttribute(k,value) self._attrs[k]=value end
function I:GetAttribute(k) return self._attrs[k] end
function I:Destroy() for _,c in self:GetChildren() do c:Destroy() end; self.Parent=nil; self._destroyed=true end
function I:ClearAllChildren() for _,child in self:GetChildren() do child:Destroy() end end
function I:GetServerTimeNow() return self._now or 0 end
function I:Clone()
	local copy=new(self.ClassName)
	for k,value in self._props do if k~="Parent" then copy[k]=value end end
	return copy
end
function I:SetNetworkOwner() end
function I:PivotTo(target)
	local delta=target*self.PrimaryPart.CFrame:Inverse()
	for _,part in self:GetDescendants() do if part:IsA("BasePart") then part.CFrame=delta*part.CFrame end end
end
function I:CanSetNetworkOwnership() return true end
local enum=setmetatable({},{__index=function(t,k)
	local e=setmetatable({},{__index=function(_,name) return k.."."..name end}); rawset(t,k,e); return e
end})
local rs={FindFirstChild=function() return nil end,Shared={Config="Config",Rules="Rules",StoneLayout="StoneLayout",ItemModels="ItemModels"}}
local lighting=new("Lighting")
local workspace=new("Workspace")
local services={ReplicatedStorage=rs,Lighting=lighting,Debris={AddItem=function() end},Players={GetPlayers=function() return {} end},CollectionService={AddTag=function() end}}
local Random={}
function Random.new(seed)
	local state=seed or 12345
	return {NextNumber=function(_,lo,hi) state=state*48271%2147483647; return (lo or 0)+state/2147483647*((hi or 1)-(lo or 0)) end}
end
function M.environment(sources)
	local env={Vector3=Vector3,Vector2={new=function(x,y) return {X=x,Y=y} end},CFrame=CFrame,Color3=Color3,
		Instance={new=new},ColorSequence={new=function(...) return {...} end},NumberSequence={new=function(...) return {...} end},Enum=enum,workspace=workspace,Random=Random,
		UDim={new=function(...) return {...} end},
		UDim2={fromScale=function(...) return {...} end,fromOffset=function(...) return {...} end,new=function(...) return {...} end},
		PhysicalProperties={new=function(...) return {...} end},RaycastParams={new=function() return {} end},
		game={GetService=function(_,name) assert(services[name],"Unmocked service "..name); return services[name] end}}
	setmetatable(env,{__index=getfenv()})
	local loaded={}
	env.require=function(name)
		if loaded[name] then return loaded[name] end
		assert(sources[name],"Missing source "..tostring(name))
		local scope=setmetatable({script={Parent=setmetatable({},{__index=function(_,key) return key end})}},{__index=env})
		local fn=assert(loadstring(sources[name],name)); setfenv(fn,scope)
		loaded[name]=fn(); return loaded[name]
	end
	return env
end
return M
