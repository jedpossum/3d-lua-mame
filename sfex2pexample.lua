--older
--cpu = manager:machine().devices[":maincpu"]
--mem = cpu.spaces["program"]
--gui = manager:machine().screens[":gpu:screen"]

--Newer Mame
cpu = manager.machine.devices[":maincpu"]
mem = cpu.spaces["program"]
gui = manager.machine.screens["gpu:screen"]

dofile("libs/3dlib.lua")

--if it doesn't work use the values
X_MAX = gui.width	--512
Y_MAX = gui.height	--240
X_Center = X_MAX>>1
Y_Center = Y_MAX>>1
ANGLE_FACTOR = TAU/0x1000

function getcamera()
	cammat = maketable_i16(0x802a55b4,9)
	camscl = ScaleMatrix(cammat,ANGLE_FACTOR,9)

	cameraX = mem:read_i16(0x2A55e6)
	cameraY = mem:read_i16(0x2A55ea)
	cameraZ = mem:read_i16(0x2A55ee)

    return {Pos      = Vector(cameraX,cameraY,cameraZ),
			Right    = Vector(camscl[0],camscl[1],camscl[2]),
			Up       = Vector(camscl[3],camscl[4],camscl[5]),
			Forward  = Vector(camscl[6],camscl[7],camscl[8])};

end

function main()
	--xpos,ypos,zpos,radius,hieght,segments,color
    draw3d_cylinder(-600,64,0,400,200,16,0xffffff00)
    
	--xpos,ypos,zpos,size
	draw3d_axis(0,0,0,64)
    
	--xpos,ypos,zpos,radius,segments,rings,color
	draw3d_sphere(400,0,128,128,8,4,0xffff8000)
    
	--xpos,ypos,zpos,height,width,color
	draw3d_box(0,500,0,128,256,0xffffffff)
    
end


emu.register_frame_done(main,"frame")

