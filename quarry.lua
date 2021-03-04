--[[
    Quarry 3.0

    Ok so basically the v1 and v2 got very excessive so
    this is a full rewrite and its structure does differ from
    v1.* & v2.*

    Instead, this works as a state machine, running commands based
    on boolean flags.
]]--


local STATE = {
    ["STORAGE"] = 0,
    ["MINING"] = 1
}


function main ()
	-- For the zig zagging pattern to work, the max values have to be even
	assert(maxX % 2 == 0)
	assert(maxZ % 2 == 0)

    while true do
        
    end
end






--[[
    Mining State
]]--

local maxX = 16
local maxZ = 16
local minY = -5

local locX = 1
local locZ = 1
local activeY = -2   -- Y layer that the turtle is actually on

local slateInd = 1
local slateDir = {} -- Tracks all orientations during the mining process

-- Go back to previous mining location
function enterMiningState ()
	assertAtOrigin()

    -- Go to be 1 block below surface
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
    turtle.turnRight()
    for i=2, locZ do
        turtle.dig()
        moveForward()
    end

    -- Match y
    for i=-1, activeY do
		-- TODO: Turn Towards
        turtle.digown()
        moveDown()
    end
end


function mineSlate ()
    for i=2,maxX do
        digForward()
    end
end


function digForward ()
    turtle.dig()
	moveForward()
    turtle.digUp()
    turtle.digDown()
end


function generateSlateDirs ()
	-- So we want the turtle to move forward
	-- and then zig zag back so that we start
	-- at the same location as you started.
	local retTable = {}
	
	for i=1, maxX-1 do
		table.insert(retTable, dirs["POX"])
	end

	for i=1, maxX-1 do

	end
	
end












--[[
    Movement
]]--

local turtleX = 1
local turtleZ = 1
local turtleY = 1

local dirs = {
    ["POSX"] = 0,
    ["NEGZ"] = 1,
    ["NEGX"] = 2,
    ["POSZ"] = 3,
}
local direction = dirs["FORWARD"]


local function moveDown ()
	local ableToMove = turtle.down()

	if ableToMove == true then
		turtleY = turtleY - 1
	end

	return ableToMove == true
end


local function moveUp ()
	local ableToMove = turtle.up()

	if ableToMove == true then
		turtleY = turtleY + 1
	end

	return ableToMove == true
end


local function moveForward ()
    local ableToMove = turtle.forward()

    if ableToMove == true then
		updatePosInDir(direction)
    else

	return ableToMove == true
end


local function moveBackward ()
	local ableToMove = turtle.back()

	if ableToMove == true then
		updatePosInDir((direction + 2) % 4)
	else
	
	return ableToMove == true
end


local function assertAtOrigin ()
	assert(turtleX == 1)
	assert(turtleY == 1)
	assert(turtleZ == 1)
end


local function turnLeft ()
	turtle.turnLeft()
	direction = (direction + 1) % 4
end


local function turnRight ()
	turtle.turnRight()
	direction = (direction - 1) % 4
end


local function turnTowards (dir) 
	local delta = (dir - direction) % 4

	if delta == 3 then
		turnRight()
	elseif delta == 2 then
		turnLeft()
		turnLeft()
	else
		turnLeft()
	end
end


local function updatePosInDir (direction)
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










--[[
    Data Structures
]]--

function newQue ()
    return {
        ["backInd"] = 1,
        ["frontInd"] = 1,

        enque = function (self, item)
            self[self.frontInd] = item
            self.frontInd = self.frontInd + 1
        end,

        deque = function (self)
            local returnItem = self[self.self.backInd]
            self[self.self.backInd] = nil
            self.backInd = self.backInd + 1
            return returnItem
        end
    }
end






