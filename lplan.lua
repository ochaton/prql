---@class LogicalPlan:Base
local lplan = require 'base':extend('LogicalPlan', {'schema', 'children', '__tostring'})

---@param plan LogicalPlan
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

---returns projection of the logical plan
---@return string[]
function lplan:projection()
	local schema = self:schema()
	local projection = {}
	for _, field in pairs(schema.format) do
		table.insert(projection, field.name)
	end
	return projection
end

---@return Schema
function lplan:schema()
	error("called on abstract lplan")
end

---@return LogicalPlan[]
function lplan:children()
	error("called on abstract lplan")
end

---@return string
function lplan:__tostring()
	error("called on abstract lplan")
end

---Pretty prints the logical plan
---@return string
function lplan:pretty()
	return format(self)
end

return lplan
