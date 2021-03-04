--[[
	Maze Solver

	Will progressively try to get to the specified point (in 2D, NOT 3D),
	pathfinding with BFS and updating its internal representation of the
	plane as it comes into obstacles.
]]--

local datastructs = require "datastructs"

local BLOCKS = {
	["AIR"] = 0,
	["BLOCK"] = 1
}

local maxX = 11
local maxZ = 7

local targetCord = {11, 7}



function main ()
	turtle.refuel(1)

	local mapOfBoard = {}
	for x = 1, maxX do
		mapOfBoard[x] = {}
		for z=1, maxZ do
			mapOfBoard[x][z] = BLOCKS.AIR
		end
	end

	local pathInd = 1
	local pathCords = doBFSAndGeneratePath({1,1}, targetCord, mapOfBoard)
	while pathCords[pathInd] ~= nil do
		if travelToAdjacent(pathCords[pathInd]) then
			pathInd = pathInd + 1
		else
			pathInd = 1
			local infrontCords = cordsOfBlockInFront()
			mapOfBoard[infrontCords.x][infrontCords.z] = BLOCKS.BLOCK

			local turtlePos = {relativePosition.x, relativePosition.z}
			pathCords = doBFSAndGeneratePath(turtlePos, targetCord, mapOfBoard)
		end
	end

	turnTowards(dirs.RIGHT)
	moveForward()

	while true do
		turnLeft()
		turnLeft()
		moveUp()

		os.sleep(0.5)
		turnLeft()
		turnLeft()
		moveDown()

		os.sleep(0.5)

		turnLeft()
		turnLeft()
		os.sleep(0.5)
	end
end



-- Print Map
function print2DTable (table, mapping)
	for i=#table,1,-1 do
		local row = table[i]

		for _, state in ipairs(row) do
			write(mapping[state])
		end
		write("\n")
	end
end




function doBFSAndGeneratePath (startLoc, endLoc, mapOfBoard)
	-- Tracks node -> node links
	local connections = {}
	for x = 1, maxX do
		connections[x] = {}
		for z=1, maxZ do
			connections[x][z] = nil
		end
	end

	connections[startLoc[1]][startLoc[2]] = startLoc

	local cordsToCheck = datastructs.newQueue()
	cordsToCheck:enque(startLoc)
	local currentCord = cordsToCheck:deque()

	while currentCord ~= nil do
		if equalPosition(currentCord, endLoc) then
			break
		end

		-- Now add all adjacent squares to queue
		for _, delta in ipairs({{-1, 0}, {1, 0}, {0, -1}, {0, 1}}) do
			local testX, testZ
			testX = currentCord[1] + delta[1]
			testZ = currentCord[2] + delta[2]

			local validCord = testX >= 1 and testX <= maxX and testZ >= 1 and testZ <= maxZ
			validCord = validCord and connections[testX][testZ] == nil and mapOfBoard[testX][testZ] == BLOCKS.AIR

			if validCord then
				connections[testX][testZ] = currentCord
				cordsToCheck:enque({testX, testZ})
			end
		end

		currentCord = cordsToCheck:deque()
	end


	-- Write to path
	local dummyPathCords = {}
	local nextCord = endLoc

	while nextCord ~= nil do
		table.insert(dummyPathCords, nextCord)

		nextCord = connections[nextCord[1]][nextCord[2]]
		if nextCord and equalPosition(nextCord, startLoc) then
			nextCord = nil
		end
	end

	-- We need to reverse the list
	local pathCords = {}
	table.insert(pathCords, startLoc)
	for i=#dummyPathCords,1,-1 do
		table.insert(pathCords, dummyPathCords[i])
	end

	return pathCords
end



function equalPosition (pos1, pos2)
	return pos1[1] == pos2[1] and pos1[2] == pos2[2]
end




















-- Movement
--
-- path is array of cords {x, z}
--

function travelToAdjacent (flatCord)
	-- Check for adjacency
	local zOff = flatCord[2] - relativePosition.z
	local xOff = flatCord[1] - relativePosition.x

	local zOffByOne = math.abs(zOff) == 1
	local xOffByOne = math.abs(xOff) == 1
	local atCord = zOff == 0 and xOff == 0

	if (atCord) then
		return true
	elseif (zOffByOne and xOffByOne) or ((not zOffByOne) and (not xOffByOne)) then
		print("ERROR: Disjointed path")
		os.exit()
		return false
	end

	if zOff == 1 then
		turnTowards(dirs.RIGHT)
	elseif zOff == -1 then
		turnTowards(dirs.LEFT)
	elseif xOff == 1 then
		turnTowards(dirs.FORWARD)
	elseif xOff == -1 then
		turnTowards(dirs.BACKWARD)
	end

	if turtle.inspect() then
		return false
	end

	turtle.dig()
	return moveForward()
end



do
	relativePosition = vector.new(1, 0, 1)
	-- 0 = forward;  1 = left;  2 = backwards; 3 = right
	dirs = {["FORWARD"] = 0, ["LEFT"] = 1, ["BACKWARD"] = 2, ["RIGHT"] = 3}
	direction = 0
	deltas = {[0] = vector.new(1, 0, 0),
						[1] = vector.new(0, 0, -1),
						[2] = vector.new(-1, 0, 0),
						[3] = vector.new(0, 0, 1)}
end

function moveForward ()
	if turtle.forward() then
		relativePosition = relativePosition:add(deltas[direction])
		return true
	end

	return false
end

function moveBackward ()
	if turtle.back() then
		relativePosition = relativePosition:sub(deltas[direction])
		return true
	end

	return false
end

function moveUp ()
	if turtle.up() then
		relativePosition.y = relativePosition.y + 1
		return true
	end

	return false
end

function moveDown ()
	if turtle.down() then
		relativePosition.y = relativePosition.y - 1
		return true
	end

	return false
end

function turnTowards (dir)
	local deltaRot = dir - direction
	if deltaRot == 3 then
		turnRight()
	elseif deltaRot == -3 then
		turnLeft()
	end

	while dir ~= direction do
		if deltaRot > 0 then
			turnLeft()
		else
			turnRight()
		end
	end
end

function turnLeft ()
	turtle.turnLeft()
	direction = (direction + 1) % 4
end

function turnRight()
	turtle.turnRight()
	direction = (direction - 1) % 4
end

function cordsOfBlockInFront()
	return relativePosition:add(deltas[direction])
end

function vecStr(vec)
	return "(" .. tostring(vec.x) .. "," .. tostring(vec.y) .. "," .. tostring(vec.z) .. ")"
end











main()
	