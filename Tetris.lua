scriptId = "com.turingLab.tetris"
scriptTitle = "Tetris"
scriptUrl = ""

centerRoll = 0
deltaRoll = 0

count = 0
fastCount = 0

actionStart = 0
newTime = 0
isItTime = false

--[[
Commands:
-Roll the arm to either side to rotate the pieces
-Double tap to calibrate the roll's center value
-Utilize the fist action to make the bricks fall faster
-By waving in and out, move the pieces to the left- and right hand side, respectively
-To pause and unpause the game spread the fingers
]]

function onForegroundWindowChange(app, title)
	myo.debug("App on Foreground: "  .. app .. " , Its title is: " .. title)
	local titleMatch = (string.match(title, "Tetris") ~= nil or string.match(title, "tetris") ~= nil) and not(string.match(title, "Tetris.lua"))
--[[
	if(titleMatch) then
		myo.setLockingPolicy("none")
	else
		myo.setLockingPolicy("standard")
	end

	return titleMatch]]
	myo.setLockingPolicy("none")
	return true
end

function onPoseEdge(pose, edge)
	if(edge == "on") then
		actionStart = myo.getTimeMilliseconds()
		forLefties(pose)
		if(pose == "fist") then
			--"down" key
			checkTime()
			if(isItTime) then
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
		elseif(pose == "waveIn") then
			--move left
			left()
		elseif(pose == "waveOut") then
			--move right
			right()
		elseif(pose == "fingersSpread") then
			--pause/unpause
			togglePause()
		end
	else
		actionStart = 0
	end
end

function onPeriodic()

	--keep gathering the roll value to be evaluated and decide the movement's direction
	deltaRoll = deltaRadians(centerRoll, myo.getRoll())
	--myo.debug("DeltaRoll: " .. tostring(deltaRoll))
	count = count + 1

	if(deltaRoll > 0.3 or deltaRoll < -0.3) and count >= 100 then
		myo.keyboard("up_arrow", "press")
		count = 0
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
	myo.debug(newTime)
	myo.debug(actionStart)

	if(newTime >= actionStart+400) then
		isItTime = true
	else
		isItTime = false
	end
	myo.debug(tostring(isItTime))
end