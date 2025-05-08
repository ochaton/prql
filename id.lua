local lexpr = require 'lexpr'

---@class Id:lexpr
---@field name string
local Id = lexpr:extend('Id')

function Id:_init(name)
	assert(type(name) == "string", "name must be a string")
	self.name = name
end

function Id:__tostring()
	return '#'..self.name
end

---@param input LogicalPlan
---@return FieldDef
function Id:tofield(input)
	for _, f in pairs(input:schema().format) do
		if f.name == self.name then
			return f
		end
	end
	error("field '"..self.name.."' not found in schema")
end

assert(Id:implements(lexpr))

return Id
