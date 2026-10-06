--!strict
local Stone=require("../src/shared/StoneLayout")
local Rules=require("../src/shared/Rules")
local checks=0
local function check(condition:boolean,message:string) checks+=1; assert(condition,message) end
for _,seed in {31415,31486,1,123456,987654} do
	local cells=Stone.build(52,38,seed)
	check(#cells==38,"Stone count")
	local total=0
	for i,cell in cells do
		check(cell.area>65,"No tiny unplayable stones")
		check(Stone.contains(cell.polygon,cell.center),"Spawn/item centroid is inside stone")
		check(#cell.polygon>=3,"Valid polygon")
		local triangles=0
		for j=1,#cell.polygon do
			local a,b,c=cell.center,cell.polygon[j],cell.polygon[j%#cell.polygon+1]
			local area=((b.x-a.x)*(c.z-a.z)-(b.z-a.z)*(c.x-a.x))/2
			check(area>=-1e-7,"Star-shaped stone triangulation winding")
			triangles+=area
		end
		check(math.abs(triangles-cell.area)<1e-4,"Triangle prisms cover polygon area")
		for _,p in cell.polygon do check(math.sqrt(p.x*p.x+p.z*p.z)<54,"Stone stays inside circular boundary") end
		for j,other in cells do
			if i~=j then check(not Stone.contains(other.polygon,cell.center),"Distinct stone interiors") end
		end
		total+=cell.area
	end
	check(total>7400 and total<8500,"Near-circular area, approximately 2x old width")
end
check(Rules.botCount(0,"FFA",6,7)==0,"No bots without humans")
check(Rules.botCount(1,"FFA",6,7)==5,"Solo gets five opponents")
check(Rules.botCount(1,"Squads",6,7)==7,"Solo squads gets two complete teams")
check(Rules.botCount(4,"Duos",6,7)==2,"Fill to six for duos")
check(Rules.botCount(6,"FFA",6,7)==0,"No filler when server has enough players")
check(Rules.botCount(16,"Squads",6,7)==0,"No overflow at max humans")
print("PASS: "..checks.." geometry and NPC-fill assertions")
