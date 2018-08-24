scriptId = "com.turingLab.tetris"
scriptTitle = "Tetris"
scriptUrl = ""

centerRoll = 0
deltaRoll = 0

centerYaw = 0
deltaYaw = 0

centerPitch = 0
deltaPitch = 0

countR = 0
countY = 0
countP = 0

--[[
Commands:
-Roll the arm to either side to rotate the pieces
-Double tap to calibrate the roll's center value
-Lowering the arm makes the bricks fall faster
-Changes in yaw move the pieces to the left- and right hand side, respectively
-To pause and unpause the game spread the fingers
]]

function onForegroundWindowChange(app, title)
	--myo.debug("App on Foreground: "  .. app .. " , Its title is: " .. title)
	local titleMatch = (string.match(title, "Tetris") ~= nil or string.match(title, "tetris") ~= nil) and not(string.match(title, "Tetris.lua"))

	if(titleMatch) then
		myo.setLockingPolicy("none")
	else
		myo.setLockingPolicy("standard")
	end

	return titleMatch
	
	--[[myo.setLockingPolicy("none")
	return true]]
end

function onPoseEdge(pose, edge)
	if(edge == "on") then
		forLefties(pose)
		if(pose == "doubleTap") then
			--center the roll value
			center()
		elseif(pose == "fingersSpread") then
			--pause/unpause
			togglePause()
		end
	end
end

function onPeriodic()
	--keep gathering the roll, pitch & yaw values to evaluate and decide on the movement's direction
	deltaRoll = deltaRadians(centerRoll, myo.getRoll())
	deltaYaw = deltaRadians(centerYaw, myo.getYaw())
	deltaPitch = deltaRadians(centerPitch, myo.getPitch())

	countR = countR + 1
	countY = countY + 1
	countP = countP + 1

	if(deltaRoll > 0.3 or deltaRoll < -0.3) and countR >= 100 then
		myo.keyboard("up_arrow", "press")
		countR = 0
	end

	if(countY >= 25) then
		if(deltaYaw > 0.2) then
			myo.keyboard("right_arrow", "press")
			myo.debug("Moving right")
			countY = 0
		elseif(deltaYaw < -0.2) then
			myo.keyboard("left_arrow", "press")
			myo.debug("Moving left")
			countY = 0
		end
	end

	--myo.debug("Pitch value:  " .. tostring(myo.getPitch()))

	if(deltaPitch < -0.3) and countP >= 10 then 
		myo.keyboard("down_arrow", "press")
		countP = 0
	end
end

function deltaRadians(old, new)
	local delta = new - old

	if(delta < -math.pi) then
		delta = delta + 2*math.pi
	elseif(delta > math.pi) then
		delta = -2*math.pi + delta
	end
	return delta
end

function forLefties(pose)
	if(myo.getArm() == "left") then
		if(pose == "waveIn") then
			pose = "waveOut"
		elseif(pose == "waveOut") then
			pose = "waveIn"
		end
	end
	return pose
end

--Basic commands:
function center() 
	centerRoll = myo.getRoll()
	centerYaw = myo.getYaw()
	centerPitch = myo.getPitch()
	myo.vibrate("short")
	myo.debug("Centered")
end

function togglePause()
	myo.keyboard("escape", "press")
	myo.debug("Pause/Unpause")
end

function left()
	myo.keyboard("left_arrow", "press")
	myo.debug("Left")
end

function right()
	myo.keyboard("right_arrow", "press")
	myo.debug("Right")
end	