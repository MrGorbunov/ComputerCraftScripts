--[[
    The Concretor - v0.1
    
    This turtle will convert concrete powder to concrete,
    by constantly placing down concrete powder and then
    mining it. It assumes its safe to place down concrete.
 
    TODO: Place the items into an adjacent chest.
    TODO: Read from config
]]--
 
function main ()
	-- Wait for user to setup turtle inventory
  term.clear()
	print("Hello!\nTo begin setup, press enter.")
	io.read()

	print("")
	print("Would you like me to place concrete into a chest below? (y/n)")
	local placeIntoChest = io.read() == "y"

	print("")
	print("Would you like me to pull powder from a chest above? (y/n)")
	local pullFromAbove = io.read() == "y"
	
	-- Do some setup, now that things have starte
	local POWDER_LIST = newSet()
	POWDER_LIST:add("minecraft:white_concrete_powder")
	POWDER_LIST:add("minecraft:orange_concrete_powder")
	POWDER_LIST:add("minecraft:magenta_concrete_powder")
	POWDER_LIST:add("minecraft:light_blue_concrete_powder")
	POWDER_LIST:add("minecraft:yellow_concrete_powder")
	POWDER_LIST:add("minecraft:lime_concrete_powder")
	POWDER_LIST:add("minecraft:pink_concrete_powder")
	POWDER_LIST:add("minecraft:gray_concrete_powder")
	POWDER_LIST:add("minecraft:light_gray_concrete_powder")
	POWDER_LIST:add("minecraft:cyan_concrete_powder")
	POWDER_LIST:add("minecraft:purple_concrete_powder")
	POWDER_LIST:add("minecraft:blue_concrete_powder")
	POWDER_LIST:add("minecraft:brown_concrete_powder")
	POWDER_LIST:add("minecraft:green_concrete_powder")
	POWDER_LIST:add("minecraft:red_concrete_powder")
	POWDER_LIST:add("minecraft:black_concrete_powder")

	local CONCRETE_LIST = newSet()
	CONCRETE_LIST:add("minecraft:white_concrete")
	CONCRETE_LIST:add("minecraft:orange_concrete")
	CONCRETE_LIST:add("minecraft:magenta_concrete")
	CONCRETE_LIST:add("minecraft:light_blue_concrete")
	CONCRETE_LIST:add("minecraft:yellow_concrete")
	CONCRETE_LIST:add("minecraft:lime_concrete")
	CONCRETE_LIST:add("minecraft:pink_concrete")
	CONCRETE_LIST:add("minecraft:gray_concrete")
	CONCRETE_LIST:add("minecraft:light_gray_concrete")
	CONCRETE_LIST:add("minecraft:cyan_concrete")
	CONCRETE_LIST:add("minecraft:purple_concrete")
	CONCRETE_LIST:add("minecraft:blue_concrete")
	CONCRETE_LIST:add("minecraft:brown_concrete")
	CONCRETE_LIST:add("minecraft:green_concrete")
	CONCRETE_LIST:add("minecraft:red_concrete")
	CONCRETE_LIST:add("minecraft:black_concrete")

	local CHEST_LIST = newSet()
	CHEST_LIST:add("minecraft:chest")
	CHEST_LIST:add("ironchest:iron_chest")
	CHEST_LIST:add("ironchest:copper_chest")
	CHEST_LIST:add("ironchest:silver_chest")
	CHEST_LIST:add("ironchest:gold_chest")
	CHEST_LIST:add("ironchest:diamond_chest")
	CHEST_LIST:add("ironchest:crystal_chest")
	CHEST_LIST:add("ironchest:obsidian_chest")


	-- Now do some checks because its startup
  local slowWriteSpeed = 100
	print("")
	textutils.slowWrite("Checking for valid setup.", slowWriteSpeed)
	checkForValidInventory(POWDER_LIST)
	textutils.slowWrite("...", slowWriteSpeed * 2)
	textutils.slowWrite("...", slowWriteSpeed / 6)
	checkForValidChestSetup(CHEST_LIST, placeIntoChest, pullFromAbove)
	textutils.slowWrite(".", slowWriteSpeed / 2)
	checkForValidConcreteSetup(CONCRETE_LIST, POWDER_LIST)
	textutils.slowWrite("..", slowWriteSpeed / 6)

	print("")
	textutils.slowPrint("All checks passed, beginning! ", slowWriteSpeed)
	print("")
	print("")

	-- And now the actual main loop
	while true do
		if placeIntoChest then
			while selectNonPowder(POWDER_LIST) do
				turtle.dropDown()
			end
		end

		if pullFromAbove and canTakeMorePowder() then
			selectEmptySlot()
			turtle.suckUp()
		end

		-- These two functions have assertions that will exit the program
		-- on fail.
		checkForValidInventory(POWDER_LIST)
		selectConcretePowder(POWDER_LIST)

		-- Now keep going until slot is empty
		while activeSlotStillGood(POWDER_LIST) do
			-- Checking the inventory actually takes time,
			-- so we do 8 powder at a time to minimize the effect
			-- of the inventory checks
			for i=1,8 do
				turtle.place()
				turtle.dig()
			end
		end
	end
end



function selectConcretePowder (POWDER_LIST)
	local itemData = turtle.getItemDetail()

	if (itemData and POWDER_LIST:contains(itemData.name)) then
			-- This means we are already selecting concretepowder
			return
	end

	for i=1, 16 do
			itemData = turtle.getItemDetail(i)
			if (itemData and POWDER_LIST:contains(itemData.name)) then
					turtle.select(i)
					return
			end
	end

	assert(false, "No more concrete powder left! Could not select the next concrete powder")
end



function selectNonPowder (POWDER_LIST)
	for i=1, 16 do
			itemData = turtle.getItemDetail(i)
			if (itemData and not POWDER_LIST:contains(itemData.name)) then
					turtle.select(i)
					return true
			end
	end

	return false
end



function selectEmptySlot ()
	for i=1, 16 do
			itemData = turtle.getItemDetail(i)
			if (not itemData) then
					turtle.select(i)
					return true
			end
	end

	return false
end



function canTakeMorePowder ()
	local totalEmptySlots = 0

	for i=1, 16 do
			local itemData = turtle.getItemDetail(i)
			if (itemData == nil) then
					totalEmptySlots = totalEmptySlots + 1
			end
	end

	return totalEmptySlots > 1
end



function activeSlotStillGood (POWDER_LIST)
	local itemData = turtle.getItemDetail()

	if (itemData == nil) then
			return false
	elseif (not POWDER_LIST:contains(itemData.name)) then
			return false
	end

  return true
end



function checkForValidInventory (POWDER_LIST)
	-- This has 2 assertions:
	--   * There is at least one empty slot
	--   * There is at least 1 concrete powder

	local totalEmptySlots = 0
	local totalConcretePowder = 0

	for i=1, 16 do
			local itemData = turtle.getItemDetail(i)
			if (itemData == nil) then
					totalEmptySlots = totalEmptySlots + 1
			elseif (itemData and POWDER_LIST:contains(itemData.name)) then
					totalConcretePowder = totalConcretePowder + turtle.getItemCount(i)
			end
	end
	
	assert(totalEmptySlots >= 2, "0 or 1 empty slots! Make sure to leave at least two empty slot for this turtle to operate safely.")
	assert(totalConcretePowder >= 1, "No concrete powder found, am turning off\n\nNote: I need at least 1 powder in my inventory to start.")
end



function checkForValidConcreteSetup (CONCRETE_LIST, POWDER_LIST)
	-- Checks that 
	--   * a concrete powder can be placed down,
	--   * it will then turn into concrete.
	selectConcretePowder(POWDER_LIST)
	turtle.place()
	local exists, itemData = turtle.inspect()

	assert(itemData ~= nil, "Improper Setup! The placed concrete powder is no longer in front of the turtle.")
	assert(CONCRETE_LIST:contains(itemData.name), "Improper Setup! The placed concrete powder did not convert into concrete.")
	turtle.dig()
end



function checkForValidChestSetup (CHEST_LIST, placeIntoChest, pullFromAbove)
	-- Checks that
	--   * if placing into chest, it checks for a chest below
	--      = does NOT check for chest emptiness
	--   * if pulling from chest, it checks for a chest above
	if placeIntoChest then
		blockBelowExists, blockInfo = turtle.inspectDown()

		assert(blockBelowExists, "Improper Setup! You said Y to placing into a chest below. However, no block was detected below.")

		assert(CHEST_LIST:contains(blockInfo.name), "Improper Setup! You said Y to placing into a chest below. However, an improper block was detected below. Try using a different type of chest, or talk to Michael.")
	end

	if pullFromAbove then
		blockBelowExists, blockInfo = turtle.inspectUp()

		assert(blockBelowExists, "Improper Setup! You said Y to pulling from above. However, no block was detected above the turtle.")

		assert(CHEST_LIST:contains(blockInfo.name), "Improper Setup! You said Y to pulling from a chest above. However, an improper block was detected above. Try using a different type of chest, or talk to Michael.")
	end
end



function newSet ()
	local s = {}

	function s:add (key)
			s[key] = 0
	end

	function s:remove (key)
			s[key] = nil
	end

	function s:contains (key)
			return s[key] ~= nil
	end

	return s
end









main()
