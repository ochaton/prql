local base = require 'base'

local plans = require 'plan'
local lexpr = require 'lexpr'

---@class QL:Base
---@field _aliases table<string, boolean>
---@param plan LogicalPlan
local ql = base:extend('ql')

---@private
---@param plan LogicalPlan
---@param aliases? table<string, boolean>
function ql:_init(plan, aliases)
	assert(plan:as('LogicalPlan'), "plan must be a LogicalPlan")
	self.plan = plan
	self._aliases = aliases or {}
end

function ql:fork(plan)
	return ql:new(plan, self._aliases)
end

function ql:_alias()
	local pref = "_expr"
	for i = 0, math.huge do
		local alias = pref..i
		if not self._aliases[alias] then
			self._aliases[alias] = true
			return alias
		end
	end
end

---@param path string|{string: string} path of the table
---@param source DataSource
---@return QL
function ql.from(path, source)
	local plan
	if type(path) == 'table' then
		local _
		_, path = next(path)

		plan = plans.Scan:new(path, source)
	elseif type(path) == 'string' then
		plan = plans.Scan:new(path, source)
	else
		error("path must be a string or a table")
	end
	return ql:new(plan)
end

---@param select table<string|number,lexpr>
---@return QL
function ql:select(select)
	assert(type(select) == 'table', "select must be a table")

	---@type lexpr[]
	local projection = {}
	for alias, expr in pairs(select) do
		local name
		if type(alias) ~= 'string' then
			name = self:_alias()
		else
			name = alias
		end
		table.insert(projection, lexpr.Alias:new(expr, name))
	end

	local plan = plans.Projection:new(self.plan, projection)
	return self:fork(plan)
end

---adds derived columns to the logical plan
---@param derive table<string|number, lexpr>
function ql:derive(derive)
	assert(type(derive) == 'table', "derive must be a table")

	---@type lexpr[]
	local add_projection = {}
	for alias, expr in pairs(derive) do
		local name
		if type(alias) ~= 'string' then
			name = self:_alias()
		else
			name = alias
		end
		table.insert(add_projection, lexpr.Alias:new(expr, name))
	end

	for _, f in pairs(self.plan:schema().format) do
		table.insert(add_projection, lexpr.f(f.name))
	end

	return self:fork(plans.Projection:new(self.plan, add_projection))
end

---@param expr lexpr
---@return QL
function ql:filter(expr)
	return self:fork(plans.Filter:new(self.plan, expr))
end


---@param aggr table<string, lexpr>
---@return QL
function ql:aggregate(aggr)
	assert(type(aggr) == 'table', "aggregate must be a table")

	local aggregates = {}
	for alias, expr in pairs(aggr) do
		local name
		if type(alias) ~= 'string' then
			name = self:_alias()
		else
			name = alias
		end
		table.insert(aggregates, lexpr.Alias:new(expr, name))
	end

	return self:fork(plans.Aggregate:new(self.plan, self.group_by or {}, aggregates))
end

---@param params {[1]: lexpr[], [2]: fun(QL):QL} parameters
---@return QL
function ql:group(params)
	assert(#params == 2, "group must have 2 parameters")
	local group_by = params[1]
	local aggr = params[2]
	assert(type(group_by) == 'table', "group_by must be a table")
	assert(type(aggr) == 'function', "aggregate must be a function")

	self.group_by = group_by
	return aggr(self)
end

---@param l integer?
---@param r integer?
---@return QL
function ql:take(l, r)
	local lim, off

	off = (l or 1) - 1
	lim = r

	assert(lim == nil or lim >= 0, "limit must be >= 0")
	assert(off == nil or off >= 0, "offset must be >= 0")

	return self:fork(plans.Limit:new(self.plan, lim, off))
end

---@param expr lexpr[]
---@return QL
function ql:sort(expr)
	return self:fork(plans.Sort:new(self.plan, expr))
end

return ql
