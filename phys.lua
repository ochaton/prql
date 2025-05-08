local base = require 'base'

---@class PhysicalPlan:Base
local plan = base:extend('plan', {'__tostring', 'children', 'schema', 'execute'})

---@return Schema
function plan:schema()
	error('called on abstract plan')
end

function plan:__tostring()
	error('called on abstract plan')
end

---@return PhysicalPlan[]
function plan:children()
	error('called on abstract plan')
end

---@return fun.iterator<box.tuple<any,any>,nil>
function plan:execute()
	error('called on abstract plan')
end

---@param plan PhysicalPlan
---@param indent integer?
---@return string
local function format(plan, indent)
	indent = indent or 0
	local strbuf = {}
	table.insert(strbuf, ('  '):rep(indent))
	table.insert(strbuf, tostring(plan))
	table.insert(strbuf, '\n')

	for _, child in pairs(plan:children()) do
		table.insert(strbuf, format(child, indent + 1))
	end

	return table.concat(strbuf, "")
end

---@return string
function plan:pretty()
	return format(self)
end

return plan
