scriptId = "com.turingLab.prothesis"
scriptTitle = "MYO-GalileoHand"
scriptUrl = ""

--[[
	-Do a fist to activate the selected action
	-Double tap to deactivate the action
	-Wave in to move back in the menu
	-To advance in the action menu, wave out or spread your fingers
]]

--[[
	Notes regarding wearing the MYO on the bicep:
	-to create a fist, contract the muscle once
	-to imitate waveIn, move the arm inwards
	-rotating the arm on its axis causes a waveOut-/fingersSpreadlike action (more often is fingerSpread)
	-contracting the bicep twice in a quick manner emulates doubleTap
]]

function onForegroundWindowChange(app, title)
	--myo.debug("App on Foreground: " .. app .. " , Its title is: " .. title)

	local stringMatch = string.match(title, "PuTTY") ~= nil

	if(stringMatch) then
		myo.setLockingPolicy("none")
	else
		myo.setLockingPolicy("standard")
	end

	return stringMatch
	--[[myo.setLockingPolicy("none")
	return true]]
end

function onPoseEdge(pose, edge)
	if(edge == "on") then
		pose = forLefties(pose)
		if(pose == "fist") then
			myo.keyboard("a", "press")			--Activate action
			myo.keyboard("return", "press")
		elseif(pose == "doubleTap") then
			myo.keyboard("d", "press")			--Deactivate action
			myo.keyboard("return", "press")
		elseif(pose == "waveIn") then
			myo.keyboard("p", "press")			--move back to Previous action
			myo.keyboard("return", "press")
			doubleVibrate()
		elseif(pose == "fingersSpread" or pose == "waveOut") then
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

--[[
	For our custom calibration profile:
	-similar to the described above, but for waveOut you just move your arm outwards
	-fingersSpread is not supported properly
]]