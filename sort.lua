local lplan = require 'lplan'

---@class Sort:LogicalPlan
---@field order lexpr[] order of sorting
local Sort = lplan:extend('Sort')

---@param plan LogicalPlan
---@param order lexpr[]
function Sort:_init(plan, order)
	self.plan = plan
	self.order = order
end

function Sort:__tostring()
	local order = {}
	for _, expr in ipairs(self.order) do
		table.insert(order, tostring(expr))
	end
	return ("Sort: %s"):format(table.concat(order, ", "))
end

function Sort:children()
	return {self.plan}
end

function Sort:schema()
	return self.plan:schema()
end

Sort:implements(lplan)
return Sort
