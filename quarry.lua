--[[
    Quarry 3.0

    Ok so basically the v1 and v2 got very excessive so
    this is a full rewrite and its structure does differ from
    v1.* & v2.*

    Instead, this works as a state machine, going to different
		loops based on state.

		-- TODO: Mine our first layer alone
]]--



function main ()
	-- For the zig zagging pattern to work, the max values have to be even
	assert(maxX % 2 == 0)
	assert(maxZ % 2 == 0)

	-- Initial values
	turtle.refuel(1)
	slateDirs = generateSlateDirs()
	activeState = states["RESUPPLY"]

	-- Main loop
	while activeState ~= states["DONE"] do
		if activeState == states["MINING"] then
			loopMining()
		elseif activeState == states["RESUPPLY"] then
			loopResupply()
		end
	end

	loopResupply()
	loopDone()
end














--[[
	State Machine Functions
]]--

do
	states = {
		["MINING"] = 0,
		["RESUPPLY"] = 1,
		["DONE"] = 2
	}
	activeState = states["RESUPPLY"]
end


function loopMining ()
	-- Enter the mine
	gotoLastMiningLocation()

	-- Mining Loop
	local canKeepMining = true

	while canKeepMining and not finishedMining() do
		canKeepMining = mineSlate()

		if canKeepMining then
			activeY = activeY - 3

			if not finishedMining() then
				turtle.digDown()
				moveDown()
				turtle.digDown()
				moveDown()
				turtle.digDown()
				moveDown()
			end
		end
	end

	savePos()
	gotoOriginFromMine()

	if finishedMining() then
		activeState = states["DONE"]
	else
		activeState = states["RESUPPLY"]
	end
end


function loopResupply ()
	refuelToThreshold()
	dumpAndResupply()
	refuelToThreshold()

	if needToRefuel() then
		-- Try one more time to get more fuel
		dumpAndResupply()

		if needToRefuel() then
			-- Really out of fuel
			activeState = states["DONE"]
			return
		end
	end

	activeState = states["MINING"]
end


function loopDone ()
	assertAtOrigin()

	turnTowards(dirs["POSZ"])
	moveForward()
	moveForward()
	moveForward()
	moveForward()

	turnTowards(dirs["POSX"])
	moveForward()
	moveForward()
end


















--[[
	Data Structures
]]--

function newSet ()
	local s = {}

	function s:addKey (key)
		s[key] = 0
	end

	function s:contains (key)
		return s[key] ~= nil
	end

	function s:removeKey (key)
		s[key] = nil
	end

	return s
end


















--[[
	Mining State
]]--
do
	maxX = 4
	maxZ = 4
	minY = -3    -- target - start + 1
							 -- 5 - start + 1
							 -- 6 - start

	locX = 1
	locZ = 1
	activeY = -2   -- Y layer that the turtle is actually on

	slateInd = 1
	slateDirs = {} -- Tracks all orientations during the mining process
end


--
-- Mining Mining functions (as opposed to movement)
function mineSlate ()
	-- The turtle can mine above and below itself,
	-- so it's faster to mine 3 high-sections at a time.
	-- I refer to a 3 high section as a slate, as opposed to a layer
	for i=slateInd,#slateDirs do
		turnTowards(slateDirs[i])
		digForward()
		slateInd = slateInd + 1

		if needToRefuel() then
			refuelToThreshold()

			if needToRefuel() then
				return false
			end
		elseif not areAnyEmptySlotsLeft() then
			return false
		end
	end

	slateInd = 1
	return true
end


function digForward ()
	repeat
		-- This is a a loop in the event of sand
		turtle.dig()
	until moveForward()
	
	turtle.digUp()
	turtle.digDown()
end


function generateSlateDirs ()
	-- So we want the turtle to move forward
	-- and then zig zag back so that we start
	-- at the same location as you started.
	local retTable = {}

	for i=1, maxX-1 do
		table.insert(retTable, dirs["POSX"])
	end
	table.insert(retTable, dirs["POSZ"])

	for i=1, maxX/2 do
		-- Go to +Z
		for j=1, maxZ-2 do
			table.insert(retTable, dirs["POSZ"])
		end
		table.insert(retTable, dirs["NEGX"])

		-- Go to -Z
		for j=1, maxZ-2 do
			table.insert(retTable, dirs["NEGZ"])
		end

		if i ~= maxX / 2 then
			table.insert(retTable, dirs["NEGX"])
		else
			table.insert(retTable, dirs["NEGZ"])
		end
	end

	return retTable
end



--
-- Mining Movement Functions
function finishedMining ()
	return activeY < minY
end


function savePos ()
	locX = turtleX
	locZ = turtleZ
end


function gotoLastMiningLocation ()
	assertAtOrigin()

	-- Go to be 1 block below surface
	turnTowards(dirs["POSX"])
	turtle.digDown()
	moveDown()
	turtle.digDown()
	moveDown()

	-- Match x
	for i=2, locX do
			turtle.dig()
			moveForward()
	end

	-- Match z
	turnRight()
	for i=2, locZ do
			turtle.dig()
			moveForward()
	end

	-- Match y
	for i=-2, activeY, -1 do
			turtle.digDown()
			moveDown()
	end
end


function gotoOriginFromMine ()
	-- Go to be 1 block below surface
	for i=turtleY, -2 do
		moveUp()
	end

	-- Match z
	turnTowards(dirs["NEGZ"])
	for i=locZ, 2, -1 do
		moveForward()
	end

	-- Match x
	turnTowards(dirs["NEGX"])
	for i=locX, 2, -1 do
		moveForward()
	end

	-- Peep above surface
	moveUp()
	moveUp()

	assertAtOrigin()
end





















--[[
	Resupply Functions
]]--

do
	fuelWhiteList = newSet()
	fuelWhiteList:addKey("minecraft:coal")
	fuelWhiteList:addKey("minecraft:coal_block")
	fuelWhiteList:addKey("minecraft:charcoal")

	junkWhiteList = newSet()
	junkWhiteList:addKey("minecraft:cobblestone")
	junkWhiteList:addKey("minecraft:netherrack")
	junkWhiteList:addKey("minecraft:dirt")
	junkWhiteList:addKey("minecraft:diorite")
	junkWhiteList:addKey("minecraft:granite")
	junkWhiteList:addKey("minecraft:andesite")
	junkWhiteList:addKey("minecraft:end_stone")
	junkWhiteList:addKey("theabyss:abyssbrokenstone")

	minFuelThreshold = 500
end


function needToRefuel()
	return turtle.getFuelLevel() < minFuelThreshold
end


function refuelToThreshold()
	for i=1,16 do
		if not needToRefuel() then
			return
		end

		local itemInfo = turtle.getItemDetail(i)

		if itemInfo and fuelWhiteList:contains(itemInfo["name"]) then
			turtle.select(i)

			while needToRefuel() and turtle.getItemDetail() do
				turtle.refuel()
			end
		end
	end
end


function areAnyEmptySlotsLeft ()
	for i=1, 16 do
		if not turtle.getItemDetail(i) then
			-- Found a blank space
			return true
		end
	end

	return false
end




-- Dumps all items into chests but takes fuel
function dumpAndResupply ()
	assertAtOrigin()

	-- Goto Resources chest
	turnTowards(dirs["POSX"])
	moveForward()
	moveForward()
	moveUp()
	moveUp()
	dumpAllResources()

	-- Goto Junk chest
	turnRight()
	moveForward()
	turnLeft()
	dumpAllInSet(junkWhiteList)

	-- Goto Fuel chest
	turnRight()
	moveForward()
	turnLeft()
	dumpAllInSet(fuelWhiteList)
	turtle.suck()

	-- Go back to origin
	moveBackward()
	moveBackward()
	moveDown()
	moveDown()
	turnLeft()
	moveForward()
	moveForward()
	turnRight()
end


function dumpAllInSet (set)
	for i=1,16 do
		local slotInfo = turtle.getItemDetail(i)

		if slotInfo and set:contains(slotInfo["name"]) then
			turtle.select(i)
			turtle.drop()
		end
	end
end


function dumpAllResources ()
	for i=1,16 do
		local slotInfo = turtle.getItemDetail(i)

		if slotInfo then
			local itemName = slotInfo["name"]
			local containedInOtherSets = fuelWhiteList:contains(itemName) or junkWhiteList:contains(itemName)
		
			if not containedInOtherSets then
				turtle.select(i)
				turtle.drop()
			end
		end
	end
end




















--[[
	Movement
]]--

do
	turtleX = 1
	turtleZ = 1
	turtleY = 1

	dirs = {
		["POSX"] = 0,
		["NEGZ"] = 1,
		["NEGX"] = 2,
		["POSZ"] = 3,
	}
	direction = dirs["POSX"]
end


function moveDown ()
	if turtle.down() then
		turtleY = turtleY - 1
		return true
	end

	return false
end


function moveUp ()
	if turtle.up() then
		turtleY = turtleY + 1
		return true
	end

	return false
end


function moveForward ()
	if turtle.forward() then
		updatePosInDir(direction)
		return true
	end

	return false
end


function moveBackward ()
	if turtle.back() then
		updatePosInDir((direction + 2) % 4)
		return true
	end

	return false
end


function assertAtOrigin ()
	assert(turtleX == 1)
	assert(turtleY == 1)
	assert(turtleZ == 1)
end


function turnLeft ()
	turtle.turnLeft()
	direction = (direction + 1) % 4
end


function turnRight ()
	turtle.turnRight()
	direction = (direction - 1) % 4
end


function turnTowards (dir) 
	local delta = dir - direction
	local absDelta = math.abs(delta)

	if absDelta == 2 then
		turnRight()
		turnRight()
	elseif delta == -1 or delta == 3 then
		turnRight()
	elseif delta == 1 or delta == -3 then
		turnLeft()
	end
end


function updatePosInDir (direction)
	if direction == dirs["POSX"] then
		turtleX = turtleX + 1
	elseif direction == dirs["NEGX"] then
		turtleX = turtleX - 1
	elseif direction == dirs["POSZ"] then
		turtleZ = turtleZ + 1
	elseif direction == dirs["NEGZ"] then
		turtleZ = turtleZ - 1
	end
end

















main()
