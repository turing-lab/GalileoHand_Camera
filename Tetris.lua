scriptId = "com.turingLab.tetris"
scriptTitle = "Tetris"
scriptUrl = ""

centerRoll = 0
deltaRoll = 0

centerYaw = 0
deltaYaw = 0

countR = 0
countY = 0

actionStart = 0
newTime = 0
isItTime = false

--[[
Commands:
-Roll the arm to either side to rotate the pieces
-Double tap to calibrate the roll's center value
-Utilize the fist action to make the bricks fall faster
-Changes in yaw move the pieces to the left- and right hand side, respectively
-To pause and unpause the game spread the fingers
]]

function onForegroundWindowChange(app, title)
	myo.debug("App on Foreground: "  .. app .. " , Its title is: " .. title)
	local titleMatch = (string.match(title, "Tetris") ~= nil or string.match(title, "tetris") ~= nil) and not(string.match(title, "Tetris.lua"))

	--[[if(titleMatch) then
		myo.setLockingPolicy("none")
	else
		myo.setLockingPolicy("standard")
	end

	return titleMatch
	]]
	myo.setLockingPolicy("none")
	return true
end

function onPoseEdge(pose, edge)
	if(edge == "on") then
		actionStart = myo.getTimeMilliseconds()
		forLefties(pose)
		if(pose == "fist") then
			--"down" key
			myo.debug(newTime)
			myo.debug(actionStart)
			if(isItTime) then
				isItTime = false
				myo.keyboard("down_arrow", "down")
				actionStart = 0
				myo.vibrate("medium")
				myo.debug("Down is down")
			else
				myo.keyboard("down_arrow", "up")
				newTime = myo.getTimeMilliseconds()
				myo.debug("Down is up")
			end
			--faster()
		elseif(pose == "doubleTap") then
			--center the roll value
			center()
		elseif(pose == "fingersSpread") then
			--pause/unpause
			togglePause()
		end
	else
		actionStart = 0
	end
end

function onPeriodic()
	checkTime()

	--keep gathering the roll value to be evaluated and decide the movement's direction
	deltaRoll = deltaRadians(centerRoll, myo.getRoll())
	deltaYaw = deltaRadians(centerYaw, myo.getYaw())

	countR = countR + 1
	countY = countY + 1

	if(deltaRoll > 0.3 or deltaRoll < -0.3) and countR >= 100 then
		myo.keyboard("up_arrow", "press")
		countR = 0
	end

	if(countY >= 25) then
		if(deltaYaw > 0.2) then
			myo.keyboard("right_arrow", "press")
			--myo.keyboard("left_arrow", "up")
			myo.debug("Moving right")
			countY = 0
		elseif(deltaYaw < -0.2) then
			myo.keyboard("left_arrow", "press")
			--myo.keyboard("right_arrow", "up")
			myo.debug("Moving left")
			countY = 0
		end
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
	myo.vibrate("short")
	myo.debug("Centered")
end

--[[
function faster()
	if(isItTime) then
		myo.keyboard("down_arrow", "down")
		actionStart = 0
		myo.vibrate("medium")
	else
		myo.keyboard("down_arrow", "up")
		newTime = myo.getTimeMilliseconds()
	end

	myo.debug("Faster!!")
end
]]

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

function checkTime()
	if(newTime > actionStart + 400) then
		isItTime = true
	else
		isItTime = false
	end
end