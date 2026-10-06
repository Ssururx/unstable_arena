--!nonstrict
local U=require(script.Parent.Util)
local Stone=require(game:GetService("ReplicatedStorage").Shared.StoneLayout)
local G={}

-- A triangular prism made from two wedges. The thin axis is the surface normal.
function G.triangle(parent,a,b,c,thickness,color,material)
	local ab,ac,bc=b-a,c-a,c-b
	local ab2,ac2,bc2=ab:Dot(ab),ac:Dot(ac),bc:Dot(bc)
	if ab2 > ac2 and ab2 > bc2 then c,a=a,c
	elseif ac2 > bc2 and ac2 > ab2 then a,b=b,a end
	ab,ac,bc=b-a,c-a,c-b
	local cross=ac:Cross(ab)
	if cross.Magnitude < .00001 then return {} end
	local right=cross.Unit; local back=bc.Unit; local up=back:Cross(right).Unit
	local height=math.abs(ab:Dot(up))
	local parts={}
	for _,v in {
		{(a+b)/2,right,back,math.abs(ab:Dot(back))},
		{(a+c)/2,-right,-back,math.abs(ac:Dot(back))},
	} do
		if v[4] < .015 or height < .015 then continue end
		local w=Instance.new("WedgePart"); w.Name="StoneFacet"; w.Anchored=true
		w.Size=Vector3.new(thickness,height,v[4]); w.CFrame=CFrame.fromMatrix(v[1],v[2],up,v[3])
		w.Color=color; w.Material=material; w.TopSurface=Enum.SurfaceType.Smooth; w.BottomSurface=Enum.SurfaceType.Smooth
		w.CanTouch=false; w.Parent=parent; table.insert(parts,w)
	end
	return parts
end
function G.polygon(parent,polygon,y,thickness,color,material)
	local parts={}
	local function point(p) return Vector3.new(p.x,y,p.z) end
	local _,center=Stone.measure(polygon)
	for i=1,#polygon do
		for _,p in G.triangle(parent,point(center),point(polygon[i]),point(polygon[i%#polygon+1]),thickness,color,material) do table.insert(parts,p) end
	end
	return parts
end
function G.ring(parent,name,radius,width,y,height,color,material,segments,ellipse)
	local result={}; segments=segments or 72; ellipse=ellipse or 1
	for i=0,segments-1 do
		local a=i/segments*math.pi*2
		local position=Vector3.new(math.sin(a)*radius, y, math.cos(a)*radius*ellipse)
		local tangent=Vector3.new(math.cos(a),0,-math.sin(a)*ellipse).Unit
		local cf=CFrame.fromMatrix(position,tangent,Vector3.yAxis,tangent:Cross(Vector3.yAxis))
		local segmentLength=2*radius*math.tan(math.pi/segments)*math.sqrt(math.cos(a)^2+ellipse^2*math.sin(a)^2)
		local part=U.part(parent,name,Vector3.new(segmentLength+.2,height,width),cf,color,material)
		part.CanTouch=false; table.insert(result,part)
	end
	return result
end
function G.cylinder(parent,name,radius,height,cf,color,material)
	local p=U.part(parent,name,Vector3.new(height,radius*2,radius*2),cf*CFrame.Angles(0,0,math.pi/2),color,material)
	p.Shape=Enum.PartType.Cylinder; p.CanTouch=false; return p
end
function G.line(parent,name,a,b,width,color,material)
	local p=U.part(parent,name,Vector3.new(width,width,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),color,material)
	p.CanCollide=false; p.CanQuery=false; p.CanTouch=false; return p
end
return G
