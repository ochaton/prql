local fun = require 'fun'
local lplan = require 'lplan'
local t = require 'types'

---@class Aggregate:LogicalPlan
local Aggregate = lplan:extend('Aggregate')

---@param input LogicalPlan
---@param group_by lexpr[] list of group by expressions
---@param aggregates lexpr[] list of aggregate expressions
function Aggregate:_init(input, group_by, aggregates)
	self.input = input
	self.group_by = group_by
	self.aggregates = aggregates
end

function Aggregate:schema()
	local fields = {}
	for _, grby in ipairs(self.group_by) do
		table.insert(fields, grby:tofield(self.input))
	end
	for _, agg in ipairs(self.aggregates) do
		table.insert(fields, agg:tofield(self.input))
	end
	return t.Schema:new(fields)
end

function Aggregate:__tostring()
	return ('Aggregate: group_by=%s; aggregates=%s'):format(
		table.concat(fun.map(tostring, self.group_by):totable(), ", "),
		table.concat(fun.map(tostring, self.aggregates):totable(), ", ")
	)
end

function Aggregate:children()
	return { self.input }
end

assert(Aggregate:implements(lplan))

return Aggregate
