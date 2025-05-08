local base = require 'base'

---lexpr is metaclass for expression mostly
---@class lexpr:Base
---@field _default? any default value
---@operator add(lexpr, lexpr):lexpr
---@operator sub(lexpr, lexpr):lexpr
---@operator mul(lexpr, lexpr):lexpr
---@operator div(lexpr, lexpr):lexpr
---@operator mod(lexpr, lexpr):lexpr
local lexpr = base:extend('LogicalExpr', {'tofield', '__tostring'})

---@param op string
---@param left any
---@param right any
local function exec(op, left, right)
	local ltype = type(left)
	local rtype = type(right)
	if type(left) == 'table' and left[op] then
		return left[op](left, right)
	elseif type(right) == 'table' and right[op] then
		return right[op](left, right)
	else
		error("no operator "..op.." for "..ltype.." and "..rtype)
	end
end

function lexpr:__add(other) return exec('add', self, other) end
function lexpr:__sub(other) return exec('sub', self, other) end
function lexpr:__mul(other) return exec('mul', self, other) end
function lexpr:__div(other) return exec('div', self, other) end
function lexpr:__mod(other) return exec('mod', self, other) end
function lexpr:__pow(other) return exec('pow', self, other) end
function lexpr:__unm() return self:unm() end
function lexpr:__concat(other) return exec('concat', self, other) end

---@param value any default value
---@return lexpr
function lexpr:def(value)
	assert(value ~= nil, "default value cannot be nil")
	self._default = value
	return self
end

---@param input LogicalPlan
---@return FieldDef
function lexpr:tofield(input)
	error("called on abstract lexpr")
end

---prints out expression
---@return string
function lexpr:__tostring()
	return "lexpr"
end

return lexpr
