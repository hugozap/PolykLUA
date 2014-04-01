-- PolyK library ported to LUA,
-- Ported by Hugo Zapata
-- original code by Ivan Kuckir

-- 		Copyright (c) 2012 Ivan Kuckir

-- 		Permission is hereby granted, free of charge, to any person
-- 		obtaining a copy of this software and associated documentation
-- 		files (the "Software"), to deal in the Software without
-- 		restriction, including without limitation the rights to use,
-- 		copy, modify, merge, publish, distribute, sublicense, and/or sell
-- 		copies of the Software, and to permit persons to whom the
-- 		Software is furnished to do so, subject to the following
-- 		conditions:

-- 		The above copyright notice and this permission notice shall be
-- 		included in all copies or substantial portions of the Software.

-- 		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- 		EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
-- 		OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
-- 		NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
-- 		HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
-- 		WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- 		FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
-- 		OTHER DEALINGS IN THE SOFTWARE.


local PolyK = {}

function PolyK.InRect(a,b,c)
	if(b.x == c.x) then
		return (a.y >= math.min(b.y,c.y) and a.y <= math.max(b.y,c.y))
	end

	if(b.y == c.y) then
		return (a.x >= math.min(b.x,c.x) and a.x <= math.max(b.x, c.x))
	end

	if(a.x >= math.min(b.x, c.x) and a.x <= math.max(b.x,c.x) and a.y >= math.min(b.y,c.y) and a.y <= math.max(b.y,c.y)) then
		return true
	else
		return false
	end

end

function PolyK.GetLineIntersection(a1,a2,b1,b2,c)
	local dax,dbx = (a1.x - a2.x), (b1.x - b2.x)
	local day,dby = (a1.y - a2.y), (b1.y - b2.y)
	local Den = dax * dby - day * dbx
	if(Den == 0) then
		return null
	end

	local A = (a1.x * a2.y - a1.y * a2.x)
	local B = (b1.x * b2.y - b1.y * b2.x)

	local I = c
	I.x = (A*dbx - dax*B) / Den 
	I.y = (A*dby - day*B) / Den 

	if( PolyK.InRect(I,a1,a2) and PolyK.InRect(I,b1,b2)) then
		return I
	end

	return null

end

-- Is Polygon self-intersecting?
function PolyK.IsSimple(p)
	
	local n = #p / 2
	if n < 4 then 
		return true
	end

	local a1,a2,b1,b2 = {},{},{},{}
	local c = {}

	for i=0,n-1 do
		a1.x = p[2*i+1]
		a1.y = p[2*i+2];
		if i == n-1 then
			a2.x = p[1]
			a2.y = p[2]
		else
			a2.x = p[2*i+3]
			a2.y = p[2*i+4]
		end

		for j=0,n-1 do
			local skip = false
			if (math.abs(i-j)< 2 ) or (j==n-1 and i==0) or (i == n-1 and j==0) then
				skip = true
			end

			if skip == false then
				b1.x = p[2*j+1]
				b1.y = p[2*j+2]

				if (j == n-1) then
					b2.x = p[1]
					b2.y = p[2]
				else
					b2.x = p[2*j+3]
					b2.y = p[2*j+4]
				end

				if(PolyK.GetLineIntersection(a1,a2,b1,b2,c) ~= nil ) then
					return false
				end

			end
		end
	end
end

function PolyK.ContainsPoint(p,px,py)
	
	local n = #p / 2
	local ax
	local ay = p[2*n-2]-py
	local bx = p[2*n-1]-px
	local by = p[2*n]-py
	local lup

	for i=0,n-1 do
		local skip = false
		ax = bx
		ay = by
		bx = p[2*i+1] - px
		by = p[2*i+2] - py
		if(ay == by) then
			skip = true
		else
			lup = by>ay
		end
	end

	local depth = 0
	for i=1,n-1 do
		local skip = false
		ax,ay = bx,by
		bx = p[2*i+1] - px
		by = p[2*i+2] - py

		if(ay<0 and by < 0) or (ay>0 and by>0) or (ax < 0 and bx < 0) then
			skip = true
		end

		if skip == false then
			if(ay == by and math.min(ax,bx)<=0) then
				return true
			end
			if(ay ~= by) then
				local lx = ax + (bx-ax) * (-ay)/(by-ay)
				if(lx == 0) then
					return true  -- point on edge
				end
				if(lx > 0) then
					depth = depth + 1
				end

				if(ay == 0 and lup and by > ay) then
					depth = depth -1 -- hit vertex both up
				end
				if(ay == 0  and lup == false and by < ay) then
					depth = depth - 1 -- hit vertex both down
				end
				lup = by > ay
			end

		end
	end

	return (depth % 2) == 1
end

function PolyK.Convex(ax,ay,bx,by,cx,cy)
	return (ay-by)*(cx-bx) + (bx-ax)*(cy-by) >= 0
end

function PolyK.PointInTriangle(px,py,ax,ay,bx,by,cx,cy)
	local v0x = cx-ax;
	local v0y = cy-ay;
	local v1x = bx-ax;
	local v1y = by-ay;
	local v2x = px-ax;
	local v2y = py-ay;
	
	local dot00 = v0x*v0x+v0y*v0y;
	local dot01 = v0x*v1x+v0y*v1y;
	local dot02 = v0x*v2x+v0y*v2y;
	local dot11 = v1x*v1x+v1y*v1y;
	local dot12 = v1x*v2x+v1y*v2y;
	
	local invDenom = 1 / (dot00 * dot11 - dot01 * dot01);
	local u = (dot11 * dot02 - dot01 * dot12) * invDenom;
	local v = (dot00 * dot12 - dot01 * dot02) * invDenom;

	-- Check if point is in triangle
	return (u >= 0) and (v >= 0) and(u + v < 1);
end

--Returns a list with the indices of the vertices
--that make each triangle in the polygon ( doesn't return the )
function PolyK.Triangulate(p)

	local n = #p / 2
	if(n<3) then
		return {}
	end
	local tgs,avl = {},{}
	for i=0,n-1 do
		table.insert(avl,i+1)
	end
	local i = 0
	local al = n

	while (al > 3) do
		local i0 = avl[(i+0)%al+1]
		local i1 = avl[(i+1)%al+1]
		local i2 = avl[(i+2)%al+1]

		local ax,ay = p[2*i0+1], p[2*i0+2]
		local bx,by = p[2*i1+1], p[2*i1+2]
		local cx,cy = p[2*i2+1], p[2*i2+2]

		local earFound = false

		if(PolyK.Convex(ax,ay,bx,by,cx,cy)) then
			earFound = true
			for j=0,al-1 do
				local vi =  avl[j+1]
				if(vi == i0 or vi == i1 or vi == i2) then

				else
					if( PolyK.PointInTriangle(p[2*vi+1],p[2*vi+2],ax,ay,bx,by,cx,cy)) then
						earFound = false
						break
					end
				end
			end
		end

		if(earFound) then
			table.insert(tgs,i0)
			table.insert(tgs,i1)
			table.insert(tgs,i2)
			--avl.splice((i+1)%al,1) r
			local index = (i+1)%al + 1
			table.remove(avl,index)
			al = al-1
			i  = 0
		elseif (i> 3*al) then
			i = i+1
			break -- no convex angles
		else
			i = i+1
		end

	end
	table.insert( tgs, avl[1] )
	table.insert( tgs, avl[2] )
	table.insert( tgs, avl[3] )

	return tgs
end

return PolyK