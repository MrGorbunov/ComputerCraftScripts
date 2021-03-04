--[[
	Data Structures

	This file holds constructors for many datastructures

	-- TODO: Add assertion functions to verify type (check if passed object is queue, set, etc)
]]--

local datastructs = {}


function datastructs.newQueue ()
	local q = {}

	q.frontInd = 1
	q.backInd = 1

	function q:enque (element)
		if element == nil then
			return
		end

		q[q.frontInd] = element
		q.frontInd = q.frontInd + 1
	end

	function q:deque ()
		local elm = q[q.backInd]

		if elm ~= nil then
			q[q.backInd] = nil
			q.backInd = q.backInd + 1
		end

		return elm
	end

	function q:size ()
		return q.frontInd - q.backInd
	end

	return q
end


function datastructs.newSet ()
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


return datastructs
