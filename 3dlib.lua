--Mame wireframe 3d lua library

--To do
--MakeCameraMatrix with camera values for games that don't store it
--object rotation


--Globals
	PI = math.pi
	TAU = math.pi*2

--commented out cause older mame versions don't have this
--	X_MAX = gui.width
--	Y_MAX = gui.height

--Stuff needed for this script
--dofile "pathtotihs"
--the short cut for drawing on the screen set to "gui"
--example
--gui = manager.machine.screens[":screen"]
--older mame
--gui = manager:machine().screens[":screen"]

--Example Arcade SFEX2P
--[[
--Resolution data of the game
X_MAX = 512
Y_MAX = 240
X_Center = 256
Y_Center = 120

used to scale the camera matrix
ANGLE_FACTOR = TAU/4096;
--why 4096 or 0x1000
--cause it is the max value rotational values can have on ps1 hardware

function getcamera()
	cammat = maketable_i16(0x802a55b4,9);
	camscl = ScaleMatrix(cammat,ANGLE_FACTOR,9);
	cameraX = mem:read_i16(0x2A55e6);
	cameraY = mem:read_i16(0x2A55ea);
	cameraZ = mem:read_i16(0x2A55ee);

	return {Pos      = Vector(cameraX,cameraY,cameraZ),
			Right    = Vector(camscl[0],camscl[1],camscl[2]),
			Up       = Vector(camscl[3],camscl[4],camscl[5]),
			Forward  = Vector(camscl[6],camscl[7],camscl[8])};

end

]]

function maketable_i16(location,num)
	local table = {};
	for v=0,num,1 do
		table[v] = mem:read_i16(location+(v*2))
	end
	return table;
end

function maketable_u16(location,num)
	local table = {};
	for v=0,num,1 do
		table[v] = mem:read_u16(location+(v*2))
	end
	return table;
end

function maketable_i32(location,num)
	local table = {};
	for v=0,num,1 do
		table[v] = mem:read_i32(location+(v*4))
	end
	return table;
end

function maketable_u32(location,num)
	local table = {};
	for v=0,num,1 do
		table[v] = mem:read_u32(location+(v*4))
	end
	return table;
end

--VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
--draw3d function
--VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
function draw3d_line(x1,y1,z1,x2,y2,z2,color)
	fpos = {};
	pos1 = Vector(x1,y1,z1);
	pos2 = Vector(x2,y2,z2);
	camera = getcamera();

	table.insert(fpos,ProjectVertex(pos1,camera,false,false)); 
	table.insert(fpos,ProjectVertex(pos2,camera,false,false)); 

	for _,b in ipairs(fpos) do
		if b.Z < 0 then
			b.X = -b.X;
			b.Y = -b.Y;
			b.Z = 0;
		end
	end

	gui:draw_line(fpos[1].X,fpos[1].Y,fpos[2].X,fpos[2].Y,color);

end

function draw3d_axis(x,y,z,size)
	draw3d_line(x-size,y,z,x+size,y,z,0xffff1111);
	draw3d_line(x,y-size,z,x,y+size,z,0xff11ff11);
	draw3d_line(x,y,z-size,x,y,z+size,0xff1111ff);

end

function draw3d_sphere(x,y,z,radius,segments,rings,color)
	pv = {};
	cam = getcamera();
	pv.Pos = Vector(x,y,z);
	sphere_projection(cam,pv,radius,segments,rings,color);
end

function draw3d_cylinder(x,y,z,radius,sizeh,segments,color)
	pv = {};
	cam = getcamera();
	pv.Pos = Vector(x,y,z);
	cylinder_projection(cam,pv,radius,sizeh,segments,color);

end

function draw3d_simple(x,y,z,radius,color)
	pv = {};
	cam = getcamera();
	pv.Pos = Vector(x,y,z);
	diamond_projection(cam,pv,radius,color);
end

function draw3d_box(x,y,z,sizew,sizeh,color)
	pv = {};
	cam = getcamera();
	pv.Pos = Vector(x,y,z);
	box_projection(cam,pv,sizew,sizeh,color);
end



--VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
--Projection math
--VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
function sphere_projection(camera,projVert,r,segments,rings,color)
	--for speed reasons stick with low numbers
	--if you want to make it bit better go ahead
	
	local shape = {};
	local pos = projVert.Pos;

	--south
	Vert = Vector(pos.X,pos.Y+r,pos.Z);
		table.insert(shape,ProjectVertex(Vert, camera, false, false));  
	
	--north
	Vert = Vector(pos.X,pos.Y-r,pos.Z);
		table.insert(shape,ProjectVertex(Vert, camera, false, false));  
	
	for j=0,rings,1 do
		phi = PI*(j+1)/rings;

		for i=0,segments,1 do
			theta = TAU*(i+1)/segments;
			sphx = (math.sin(phi)*math.cos(theta))*r;
			sphy = math.cos(phi)*r;
			sphz = (math.sin(phi)*math.sin(theta))*r;
			Vert = Vector(sphx+pos.X,sphy+pos.Y,sphz+pos.Z)
				table.insert(shape,ProjectVertex(Vert,camera,false,false))
		end
	end

	for _,Vert in ipairs(shape) do
		if Vert.Z < 0 then
			Vert.X = -Vert.X;
			Vert.Y = -Vert.Y;
			Vert.Z = 0;
		end
	end

	--bottom
	for sp = 0,segments,1 do
		gui:draw_line(shape[1].X,shape[1].Y,shape[sp+3].X,shape[sp+3].Y,color);
	end
	
	vt = 3;
	for rg = 0,rings-2,1 do
		for sp = 0,segments-1,1 do
			gui:draw_line(shape[vt].X,shape[vt].Y,shape[vt+1].X,shape[vt+1].Y,color);
			gui:draw_line(shape[vt].X,shape[vt].Y,shape[vt+segments+1].X,shape[vt+segments+1].Y,color);
			vt = vt+1;
		end
		vt = vt+1;

	end

end

function cylinder_projection(camera,projVert,r,sizeh,segments,color)
	local shape = {};
	local pos = projVert.Pos;

	local floorY = pos.Y + sizeh/2;


	for h = 0,1,1 do
		for i = 0,segments,1 do
			theta = TAU*(i+1)/segments
			cynX = (math.cos(theta)*r)+pos.X
			cynY = floorY-sizeh*h
			cynZ = (math.sin(theta)*r)+pos.Z
			Vert = Vector(cynX,cynY,cynZ)
			table.insert(shape,ProjectVertex(Vert,camera,false,false))
		end
	end

	for _,Vert in ipairs(shape) do
		if Vert.Z < 0 then
			Vert.X = -Vert.X;
			Vert.Y = -Vert.Y;
			Vert.Z = 0;
		end
	end

	--bottom
	cvt = 1
		gui:draw_line(shape[segments].X,shape[segments].Y,shape[1].X,shape[1].Y,color);
	
	for s = 0,segments,1 do
		gui:draw_line(shape[cvt].X,shape[cvt].Y,shape[cvt+1].X,shape[cvt+1].Y,color);
		gui:draw_line(shape[cvt].X,shape[cvt].Y,shape[cvt+segments+1].X,shape[cvt+segments+1].Y,color);
		cvt = cvt+1
	end

	--top
	for s = 0,segments-1,1 do
		gui:draw_line(shape[cvt].X,shape[cvt].Y,shape[cvt+1].X,shape[cvt+1].Y,color);
		cvt = cvt + 1
	end
end

function diamond_projection(camera,projVert,r,color)
	local shape = {};
	local pos = projVert.Pos;
	
	--northpole
	Vert = Vector(pos.X,pos.Y+r,pos.Z);
		table.insert(shape,ProjectVertex(Vert, camera, false, false));  
	
	--southpole
	Vert = Vector(pos.X,pos.Y-r,pos.Z);
		table.insert(shape,ProjectVertex(Vert, camera, false, false));  
	
	Vert = Vector(pos.X+r,pos.Y,pos.Z+r)
		table.insert(shape,ProjectVertex(Vert, camera, false, false));  
	Vert = Vector(pos.X-r,pos.Y,pos.Z-r)
		table.insert(shape,ProjectVertex(Vert, camera, false, false));  
	Vert = Vector(pos.X+r,pos.Y,pos.Z-r)
		table.insert(shape,ProjectVertex(Vert, camera, false, false));  
	Vert = Vector(pos.X-r,pos.Y,pos.Z+r)
		table.insert(shape,ProjectVertex(Vert, camera, false, false));  



	for _,Vert in ipairs(shape) do
		if Vert.Z < 0 then
			Vert.X = -Vert.X;
			Vert.Y = -Vert.Y;
			Vert.Z = 0;
		end
	end

	gui:draw_line(shape[1].X,shape[1].Y,shape[3].X,shape[3].Y,color);
	gui:draw_line(shape[1].X,shape[1].Y,shape[4].X,shape[4].Y,color);
	gui:draw_line(shape[1].X,shape[1].Y,shape[5].X,shape[5].Y,color);
	gui:draw_line(shape[1].X,shape[1].Y,shape[6].X,shape[6].Y,color);
	gui:draw_line(shape[3].X,shape[3].Y,shape[5].X,shape[5].Y,color);
	gui:draw_line(shape[3].X,shape[3].Y,shape[6].X,shape[6].Y,color);
	gui:draw_line(shape[4].X,shape[4].Y,shape[5].X,shape[5].Y,color);
	gui:draw_line(shape[4].X,shape[4].Y,shape[6].X,shape[6].Y,color);
	gui:draw_line(shape[2].X,shape[2].Y,shape[3].X,shape[3].Y,color);
	gui:draw_line(shape[2].X,shape[2].Y,shape[4].X,shape[4].Y,color);
	gui:draw_line(shape[2].X,shape[2].Y,shape[5].X,shape[5].Y,color);
	gui:draw_line(shape[2].X,shape[2].Y,shape[6].X,shape[6].Y,color);
end

function box_projection(camera, projVert, w, h,color)
	local shape = {};
	for j=0,1,1 do
		local pos = projVert.Pos;
		local floorY = pos.Y + h/2;                                     -- Entity pos is reset to the floor, where it actually is
		local b = Vector(pos.X + w, floorY-h*j, pos.Z+w);
		table.insert(shape, ProjectVertex(b, camera, false, false));     -- Calculate 4+4 vertices to create the AABB.

		b = Vector(pos.X + w, floorY-h*j, pos.Z-w);
		table.insert(shape, ProjectVertex(b, camera, false, false));

		b = Vector(pos.X - w, floorY-h*j, pos.Z-w);
		table.insert(shape, ProjectVertex(b, camera, false, false));

		b = Vector(pos.X - w, floorY-h*j, pos.Z+w);
		table.insert(shape, ProjectVertex(b, camera, false, false));
	end

	--bad clipping
	for _,b in ipairs(shape) do
		if b.Z < 0 then
			b.X = -b.X;
			b.Y = -b.Y;
			b.Z = 0;
		end
	end

	gui:draw_line(shape[1].X,shape[1].Y,shape[2].X,shape[2].Y,color);
	gui:draw_line(shape[1].X,shape[1].Y,shape[4].X,shape[4].Y,color);
	gui:draw_line(shape[1].X,shape[1].Y,shape[5].X,shape[5].Y,color);
	gui:draw_line(shape[2].X,shape[2].Y,shape[3].X,shape[3].Y,color);
	gui:draw_line(shape[2].X,shape[2].Y,shape[6].X,shape[6].Y,color);
	gui:draw_line(shape[3].X,shape[3].Y,shape[4].X,shape[4].Y,color);
	gui:draw_line(shape[3].X,shape[3].Y,shape[7].X,shape[7].Y,color);
	gui:draw_line(shape[4].X,shape[4].Y,shape[8].X,shape[8].Y,color);
	gui:draw_line(shape[6].X,shape[6].Y,shape[5].X,shape[5].Y,color);
	gui:draw_line(shape[6].X,shape[6].Y,shape[7].X,shape[7].Y,color);
	gui:draw_line(shape[8].X,shape[8].Y,shape[5].X,shape[5].Y,color);
	gui:draw_line(shape[8].X,shape[8].Y,shape[7].X,shape[7].Y,color);	
end

function ProjectVertex(point, camera, cullOffscreen, cullBehind)
	cullOffscreen = cullOffscreen and true;
	cullBehind = cullBehind and true;
	local p = VectorSubtract(point, camera.Pos);                        -- Move to camera space

	local IR3 =  DotProduct(camera.Forward, p);                         -- Project point's distance to the camera
	if cullBehind and (IR3 <= Y_Center) then return nil end;              -- Exit early if the point is too close to the camera
	local pScale = Y_MAX/IR3;                                               -- Perspective adjustment

	local IR1 =  DotProduct(camera.Right, p);                           -- Project point's x position to screen's right vector
	local SX = X_Center + IR1 * pScale;                                    -- Adjust projected point for perspective
	if cullOffscreen and (0 > SX or SX > X_MAX) then return nil end;    -- Exit early if the point is outside of the screen

	local IR2 =  DotProduct(camera.Up, p);                              -- Project point's y position to the screen's up vector
	local SY = Y_Center + IR2 * pScale;                                    -- Adjust projected point for perspective
	if cullOffscreen and (0 > SY or SY > Y_MAX) then return nil end;    -- Exit early if the point is outside of the screen

	return {X=SX, Y=SY, Z=IR3};
end

--############################################################
--
--############################################################
function Vector(x,y,z)
	return {X=x,Y=y,Z=z}
end

function VectorLength(v)
	return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z);
end

function VectorSubtract(v, w)
	return Vector(v.X - w.X, v.Y - w.Y, v.Z - w.Z);
end

function ScaleVector(v, a)
	return Vector(v.X * a, v.Y * a, v.Z * a);
end

function DotProduct(v, w)
	return v.X * w.X + v.Y * w.Y + v.Z * w.Z;
end

function ScaleMatrix(m,a,s)
	local scaledMatrix = {};
	for i=0,s,1 do
		scaledMatrix[i] = m[i] * a;
	end
	return scaledMatrix;
end

-- LINEAR ALGEBRA (IN-PLACE)
function VectorSubtract_IP(v,w)
	v.X = v.X - w.X;
	v.Y = v.Y - w.Y;
	v.Z = v.Z - w.Z;
end

function ScaleVector_IP(v,a)
	v.X = v.X * a;
	v.Y = v.Y * a;
	v.Z = v.Z * a;
end

--############################################################
--Camera Matrix
--############################################################
--[[
function make_cam_matrix(cx,cy,cz,max_rotation,pitch,yaw,roll)
	--WIP
	--it is better to read the actual matrix in the game
	--matrix values on ps1 are 16 bit



	R = {max_rotation,0x0000,0x0000,
		 0x0000,max_rotation,0x0000,
		 0x0000,0x0000,max_rotation};	


	cmatrix = {};

	AF = TAU/max_rotation
	
	camscl = ScaleMatrix(cmatrix,AF,9);

	return {Pos			= Vector(cx,cy,cz)
			Right		= Vector(camscl[0],camscl[1],camscl[2])
			Up			= Vector(camscl[3],camscl[4],camscl[5])
			Forward		= Vector(camscl[6],camscl[7],camscl[8])};
end
]]