local phys = require 'phys'
local fun = require 'fun'
local msgpack = require 'msgpack'

---@class ScanExec:PhysicalPlan
---@field ds DataSource data source
---@field projection string[] projection expressions
local ScanExec = phys:extend('ScanExec')

---@param ds DataSource data source
---@param projection string[] projection expressions
function ScanExec:_init(ds, projection)
	self.ds = ds
	self.projection = projection
end

---@return Schema
function ScanExec:schema()
	return self.ds:schema()
end

---@return fun.iterator<box.tuple<any,any>,nil>
function ScanExec:execute()
	return self.ds:scan()
end

function ScanExec:children()
	return {}
end

function ScanExec:__tostring()
	return ('ScanExec: schema=%s, projection=[%s]'):format(
		self:schema(),
		table.concat(self.projection, ", ")
	)
end

assert(ScanExec:implements(phys))

---@class ProjectionExec:PhysicalPlan
---@field input PhysicalPlan input plan
---@field exprs Expr[] list of expressions to evaluate
---@field _schema Schema schema of the output
local ProjectionExec = phys:extend('ProjectionExec')

---@param input PhysicalPlan
---@param schema Schema schema of the output
---@param exprs Expr[] list of expressions to evaluate
function ProjectionExec:_init(input, schema, exprs)
	self.input = input
	self.exprs = exprs
	self._schema = schema
end

function ProjectionExec:__tostring()
	return ('ProjectionExec: %s'):format(table.concat(fun.map(tostring, self.exprs):totable(), ','))
end

function ProjectionExec:children()
	return { self.input }
end

function ProjectionExec:schema()
	return self._schema
end

---@return fun.iterator<box.tuple<any,any>,nil>
function ProjectionExec:execute()
	return self.input:execute():map(function(record)
		---@type any[]
		local t = {}
		for i, expr in ipairs(self.exprs) do
			t[i] = expr:eval(record)
		end
		return self._schema:totuple(t)
	end)
end

assert(ProjectionExec:implements(phys))

---@class FilterExec:PhysicalPlan
local FilterExec = phys:extend('FilterExec')

---@param input PhysicalPlan
---@param expr Expr filter expression
function FilterExec:_init(input, expr)
	self.input = input
	self.expr = expr
end

function FilterExec:__tostring()
	return ('FilterExec: %s'):format(tostring(self.expr))
end

function FilterExec:children()
	return { self.input }
end

function FilterExec:schema()
	return self.input:schema()
end

---@return fun.iterator<box.tuple<any,any>,nil>
function FilterExec:execute()
	return self.input:execute():filter(function(record)
		return self.expr:eval(record)
	end)
end

assert(FilterExec:implements(phys))

---@class HashAggregateExec:PhysicalPlan
---@field input PhysicalPlan input plan
---@field group_by Expr[] list of group by expressions
---@field aggregates AggrExpr[] list of aggregate expressions
---@field _schema Schema schema of the output
local HashAggregateExec = phys:extend('HashAggregateExec')

---@param input PhysicalPlan
---@param group_by Expr[] list of group by expressions
---@param aggregates AggrExpr[] list of aggregate expressions
---@param schema Schema schema of the output
function HashAggregateExec:_init(input, group_by, aggregates, schema)
	self.input = input
	self.group_by = group_by
	self.aggregates = aggregates
	self._schema = schema
end

function HashAggregateExec:schema() return self._schema end
function HashAggregateExec:children() return { self.input } end

function HashAggregateExec:__tostring()
	return ('HashAggregateExec: group_by=%s; aggregates=%s'):format(
		table.concat(fun.map(tostring, self.group_by):totable(), ", "),
		table.concat(fun.map(tostring, self.aggregates):totable(), ", ")
	)
end

---@return fun.iterator<box.tuple<any,any>,nil>
function HashAggregateExec:execute()
	---@type table<string, Accumulator[]>
	local map = {}
	local key2keys = {} -- reverse table for group_key
	for _, record in self.input:execute() do -- HashAggregateExec consumes input
		local keys = {}
		for i, ge in ipairs(self.group_by) do
			keys[i] = ge:eval(record)
		end

		---@type string
		local group_key = msgpack.encode(keys)
		if not map[group_key] then
			-- create new group of accumulators
			map[group_key] = {}
			key2keys[group_key] = keys
			for i, ae in ipairs(self.aggregates) do
				map[group_key][i] = ae:newaccumulator()
			end
		end

		local accs = map[group_key]
		for i, ae in ipairs(self.aggregates) do
			accs[i]:accumulate(ae:eval(record))
		end
	end

	-- map contains the final state of each group
	-- group_keys first, then accumulators

	---@param k string
	---@param accs Accumulator[]
	return fun.map(function(k, accs)
		local keys = key2keys[k]
		local kn = #keys
		local result = {}
		for i = 1, kn do
			result[i] = keys[i]
		end
		for j = 1, #accs do
			result[kn+j] = accs[j]:final()
		end
		return self._schema:totuple(result)
	end, map)
end

assert(HashAggregateExec:implements(phys))

return {
	ScanExec = ScanExec,
	ProjectionExec = ProjectionExec,
	FilterExec = FilterExec,
	HashAggregateExec = HashAggregateExec,
}
