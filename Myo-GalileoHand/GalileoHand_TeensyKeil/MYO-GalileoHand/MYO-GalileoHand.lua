scriptId = "com.turingLab.prothesis"
scriptTitle = "MYO-GalileoHand"
scriptUrl = ""

function onForegroundWindowChange(app, title)
	--myo.debug("App on Foreground: " .. app .. " , Its title is: " .. title)

	local stringMatch = string.match(title, "PuTTY") ~= nil

	if(stringMatch) then
		myo.setLockingPolicy("none")
	else
		myo.setLockingPolicy("standard")
	end

	return stringMatch
end

function onPoseEdge(pose, edge)
	if(edge == "on") then
		pose = forLefties(pose)
		if(pose == "doubleTap") then
			myo.keyboard("a", "press")			--Activate action
			myo.keyboard("return", "press")
		elseif(pose == "fingersSpread") then
			myo.keyboard("d", "press")			--Deactivate action
			myo.keyboard("return", "press")
		elseif(pose == "waveIn") then
			myo.keyboard("p", "press")			--move back to Previous action
			myo.keyboard("return", "press")
			doubleVibrate()
		elseif(pose == "waveOut") then
			myo.keyboard("n", "press")			--move on to Next action
			myo.keyboard("return", "press")
			myo.vibrate("short")
		end
	end
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

function doubleVibrate()
	local dVCount = 0
	myo.vibrate("short")
	while(dVCount < 100) do
		dVCount = dVCount + 1
	end
	dVCount = 0
	myo.vibrate("short")
end