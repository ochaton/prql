local lplan = require 'lplan'
local t = require 'types'
local u = require 'utils'
local stringify = u.stringify

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

function Filter:__tostring() return ('Filter: %s'):format(self.expr) end
function Filter:children() return {self.input} end
function Filter:schema() return self.input:schema() end

assert(Filter:implements(lplan))

-------------------------------------------------------------

---@class Scan:LogicalPlan
---@field path string path to the data source
---@field datasource DataSource
---@field projection string[] projection list
---@field _schema Schema schema of the data source
local Scan = lplan:extend('Scan')

---@param path string path to the data source
---@param datasource DataSource
---@param projection string[]
function Scan:_init(path, datasource, projection)
	self.path = path
	self.datasource = datasource
	self.projection = projection or {}

	local schema = datasource:schema()
	if not schema then
		error("failed to derive schema for "..path)
	end
	self._schema =  schema:select(self.projection)
end

function Scan:__tostring()
	if #self.projection == 0 then
		return ('Scan: %s; projection=None'):format(self.path)
	else
		return ('Scan: %s; projection=%s'):format(self.path, table.concat(self.projection, ", "))
	end
end

function Scan:children() return {} end
function Scan:schema() return self._schema end

assert(Scan:implements(lplan))

-------------------------------------------------------------

---@class Sort:LogicalPlan
---@field input LogicalPlan
---@field order lexpr[] order of sorting
local Sort = lplan:extend('Sort')

---@param plan LogicalPlan
---@param order lexpr[]
function Sort:_init(plan, order)
	self.input = plan
	self.order = order
end

function Sort:__tostring()
	local order = {}
	for _, expr in ipairs(self.order) do
		table.insert(order, tostring(expr))
	end
	return ("Sort: %s"):format(table.concat(order, ", "))
end

function Sort:children() return {self.input} end
function Sort:schema() return self.input:schema() end

Sort:implements(lplan)

-------------------------------------------------------------

---@class Limit:LogicalPlan
---@field input LogicalPlan
---@field offset integer
---@field limit integer?
local Limit = lplan:extend('Limit')

---@param plan LogicalPlan
---@param limit integer?
---@param offset integer?
function Limit:_init(plan, limit, offset)
	self.input = plan
	if not limit and not offset then
		error("Limit and Offset must be provided")
	end
	self.offset = offset or 0
	self.limit = limit
end

function Limit:__tostring()
	if self.offset > 0 then
		if self.limit then
			return ("Limit: %d, Offset: %d"):format(self.limit, self.offset)
		else
			return ("Offset: %d"):format(self.offset)
		end
	elseif self.limit then
		return ("Limit: %d"):format(self.limit)
	end
end

function Limit:children() return {self.input} end
function Limit:schema() return self.input:schema() end

assert(Limit:implements(lplan))

-------------------------------------------------------------

---Applies list of logical expressions to the input logical plan.
---it is good for :select{} and :derive{} methods
---@class Projection:LogicalPlan
---@field input LogicalPlan
---@field exprs lexpr[] list of expressions to evaluate
local Projection = lplan:extend('Projection')

---@param input LogicalPlan
---@param exprs lexpr[]
function Projection:_init(input, exprs)
	self.input = input
	self.exprs = exprs
end

---@return LogicalPlan[]
function Projection:children() return {self.input} end

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

-------------------------------------------------------------

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
		stringify(self.group_by),
		stringify(self.aggregates)
	)
end

function Aggregate:children()
	return { self.input }
end

assert(Aggregate:implements(lplan))

return {
	Filter = Filter,
	Scan = Scan,
	Sort = Sort,
	Limit = Limit,
	Aggregate = Aggregate,
	Projection = Projection,
}