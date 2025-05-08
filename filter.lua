local lplan = require 'lplan'

---@class Filter:LogicalPlan
---@field input LogicalPlan
---@field expr lexpr expression
local Filter = lplan:extend('Filter')

---@param input LogicalPlan
---@param expr lexpr expression
function Filter:_init(input, expr)
	self.input = input
	self.expr = expr
end

function Filter:__tostring()
	return ('Filter: %s'):format(self.expr)
end

function Filter:children()
	return {self.input}
end

function Filter:schema()
	return self.input:schema()
end

assert(Filter:implements(lplan))

return Filter

