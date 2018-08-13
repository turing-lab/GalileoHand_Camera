scriptId = "com.thalmic.examples.racethesun"
scriptTitle = "Race the Sun"
scriptDetailsUrl = ""

centerYaw = 0

centerRoll = 0
deltaRoll = 0

mouseState = false
unlockedTimestamp = 0
newTime = 0


function onForegroundWindowChange(app, title)
	myo.debug("App: " .. app .. " , " .. "Title: " .. title)

	local titleMatch = string.match(title, "Race The Sun") ~= nil or string.match(title, "RaceTheSun") ~= nil

	if(string.match(title, "RaceTheSun.lua")) then
		titleMatch = false
	end

	if(titleMatch) then 
		myo.setLockingPolicy("none")
	else 
		myo.setLockingPolicy("standard")
	end

	return titleMatch
	--return true
end

function onPoseEdge(pose, edge)
	myo.debug("Detected pose: " .. pose .. " , State of edge: " .. edge)

	if(edge == "on") then 
		unlockedTimestamp = myo.getTimeMilliseconds()
		if(pose == "fist") then
			--center yaw value when a pose starts; reset it when it is done
			center()
		elseif(pose == "fingersSpread") then
			escape()
		elseif(pose == "waveIn" or pose == "waveOut") then
			if(deltaRoll > 0.2 or deltaRoll < -0.2) then
				myo.keyboard("space", "press")
				myo.debug("Jumping!")
			elseif(pose == "waveIn") then
				leftClick()
			else
				if(mouseState) then
					toggleMouse()
					unlockedTimestamp = 0
					myo.vibrate("medium")
				else
					myo.controlMouse(true)
					myo.vibrate("medium")
					newTime = myo.getTimeMilliseconds()
				end
			end
		end
	else
		unlockedTimestamp = 0
	end
end

function center()
	centerYaw = myo.getYaw()
	centerRoll = myo.getRoll()
	myo.controlMouse(false)
	myo.vibrate("short")
	myo.debug("Center")
end

function escape()
	myo.keyboard("escape", "press")
	centerYaw = 0
	myo.debug("Escape")
end

function calculateDeltaRadians(currentYaw, centerYaw)	--radians over pi suck
	local deltaYaw = currentYaw - centerYaw

	if(deltaYaw > math.pi) then 
		deltaYaw = deltaYaw - 2*math.pi
	elseif(deltaYaw < -math.pi) then
		deltaYaw = deltaYaw + 2*math.pi
	end

	return deltaYaw
end

function onPeriodic()
	if(centerYaw == 0) then
		return
	end

	local deltaYaw = calculateDeltaRadians(myo.getYaw(), centerYaw)
	if(deltaYaw > 0.1) then
		myo.keyboard("right_arrow", "down")
		myo.keyboard("left_arrow", "up")
		myo.debug("Flying right")
	elseif(deltaYaw < -0.1) then
		myo.keyboard("left_arrow", "down")
		myo.keyboard("right_arrow", "up")
		myo.debug("Flying left")
	else
		myo.keyboard("right_arrow", "up")
		myo.keyboard("left_arrow", "up")
		myo.debug("Flying straight")
	end

	deltaRoll = calculateDeltaRadians(myo.getRoll(), centerRoll)
end

function toggleMouse(mouseState)
	mouseState = not mouseState
	myo.debug("Mouse state toggled")
	return mouseState
end

function leftClick()
	myo.mouse("left", "click")
	myo.debug("Left Click")
end

function checkTime()
	myo.debug("Time checked: " .. tostring(unlockedTimestamp) .. " , NewTime: " .. tostring(newTime))
	if(newTime > unlockedTimestamp+400) then
		mouseState = true
	else
		mouseState = false
	end
end

