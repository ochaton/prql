local lplan = require 'lplan'
local t = require 'types'

---Applies list of logical expressions to the input logical plan.
---it is good for :select{} and :derive{} methods
---@class Projection:LogicalPlan
local Projection = lplan:extend('Projection')

---@param input LogicalPlan
---@param exprs lexpr[]
function Projection:_init(input, exprs)
	self.input = input
	self.exprs = exprs
end

---@return LogicalPlan[]
function Projection:children()
	return {self.input}
end

function Projection:__tostring()
	local exprs = {}
	for _, expr in ipairs(self.exprs) do
		table.insert(exprs, tostring(expr))
	end
	return ('Project: %s'):format(table.concat(exprs, ', '))
end

---@return Schema
function Projection:schema()
	---@type FieldDef[]
	local fields = {}
	for _, expr in ipairs(self.exprs) do
		table.insert(fields, expr:tofield(self.input))
	end
	return t.Schema:new(fields)
end

assert(Projection:implements(lplan))
return Projection
