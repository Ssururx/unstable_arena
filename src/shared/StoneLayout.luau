--!strict
-- Pure geometry, shared by the build and CLI geometry tests. No Roblox globals.
local Stone = {}
export type Point = {x:number,z:number}
export type Cell = {polygon:{Point},center:Point,area:number}
local function clip(poly:{Point},nx:number,nz:number,limit:number):{Point}
	local out = {}
	for i,a in poly do
		local b=poly[i%#poly+1]
		local da=a.x*nx+a.z*nz-limit; local db=b.x*nx+b.z*nz-limit
		if da <= 1e-8 then table.insert(out,a) end
		if (da < 0 and db > 0) or (da > 0 and db < 0) then
			local t=da/(da-db)
			table.insert(out,{x=a.x+(b.x-a.x)*t,z=a.z+(b.z-a.z)*t})
		end
	end
	return out
end
function Stone.measure(poly:{Point}):(number,Point)
	local twice,cx,cz=0,0,0
	for i,a in poly do
		local b=poly[i%#poly+1]; local cross=a.x*b.z-b.x*a.z
		twice+=cross; cx+=(a.x+b.x)*cross; cz+=(a.z+b.z)*cross
	end
	assert(math.abs(twice)>1e-6,"Degenerate stone polygon")
	return math.abs(twice)/2,{x=cx/(3*twice),z=cz/(3*twice)}
end
function Stone.contains(poly:{Point},point:Point):boolean
	local inside=false
	for i,a in poly do
		local b=poly[i%#poly+1]
		if (a.z>point.z)~=(b.z>point.z) and point.x<(b.x-a.x)*(point.z-a.z)/(b.z-a.z)+a.x then inside=not inside end
	end
	return inside
end
function Stone.build(radius:number,count:number,seed:number):{Cell}
	-- Deterministic local RNG: cosmetic generation never changes game RNG state.
	local state=seed%2147483647
	local function random():number state=(state*48271)%2147483647; return state/2147483647 end
	local boundary={}
	for i=0,63 do
		local a=i*math.pi/32
		local r=radius*(.965+.019*math.sin(a*3+.4)+.011*math.sin(a*7))
		table.insert(boundary,{x=math.cos(a)*r,z=math.sin(a)*r})
	end
	local points={}
	-- Sunflower seeds avoid a grid while keeping cells large enough to fight on.
	for i=1,count do
		local a=i*2.399963229728653+(random()-.5)*.26
		local r=radius*.91*math.sqrt((i-.6)/count)
		table.insert(points,{x=math.cos(a)*r+(random()-.5)*2,z=math.sin(a)*r+(random()-.5)*2})
	end
	local cells={}
	for i,p in points do
		local polygon=table.clone(boundary)
		for j,q in points do
			if i == j then continue end
			polygon=clip(polygon,q.x-p.x,q.z-p.z,(q.x*q.x+q.z*q.z-p.x*p.x-p.z*p.z)/2)
		end
		local _,center=Stone.measure(polygon)
		-- Shared long edges receive the same small, asymmetric kink from both sides.
		-- This produces interlocking fracture outlines instead of perfect Voronoi edges.
		local rough:{Point}={}
		for j,a in polygon do
			local b=polygon[j%#polygon+1]; table.insert(rough,a)
			local dx,dz=b.x-a.x,b.z-a.z; local length=math.sqrt(dx*dx+dz*dz)
			if length>11 then
				local mx,mz=(a.x+b.x)/2,(a.z+b.z)/2
				local direction=if a.x<b.x or (math.abs(a.x-b.x)<1e-6 and a.z<b.z) then 1 else -1
				local noise=math.sin(math.round(mx*100)*.13+math.round(mz*100)*.21)*.36
				table.insert(rough,{x=mx-dz/length*noise*direction,z=mz+dx/length*noise*direction})
			end
		end
		-- Narrow fissures, not holes wide enough to swallow a walking avatar.
		local inset={}
		for _,v in rough do
			local dx,dz=v.x-center.x,v.z-center.z; local length=math.sqrt(dx*dx+dz*dz)
			local scale=math.max(0,1-.16/length)
			table.insert(inset,{x=center.x+dx*scale,z=center.z+dz*scale})
		end
		local area,centroid=Stone.measure(inset)
		table.insert(cells,{polygon=inset,center=centroid,area=area})
	end
	return cells
end
return table.freeze(Stone)
