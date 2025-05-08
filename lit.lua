local lexpr = require 'lexpr'

---@class Lit:lexpr
---@field value any literal value
---@field type tuple_type_name
---@field private _str string string representation of the value
local Lit = lexpr:extend('Lit')

local t = require 'types'

local has_ffi, ffi = pcall(require, 'ffi')

---@param value any literal value
function Lit:_init(value)
	local isa = type(value)
	local ltype = ""
	if isa == "string" or isa == "number" or isa == "boolean" or isa == "nil" then
		-- ok
		ltype = isa
	elseif has_ffi and isa == "cdata" then
		if ffi.istype("int64_t", value) then
			ltype = "int64"
		elseif ffi.istype("uint64_t", value) then
			ltype = "uint64"
		else
			ltype = tostring(ffi.typeof(value))
			error("value '"..tostring(value).."' of cdata type '"..ltype.."' not supported")
		end
	else
		error("value '"..tostring(value).. "' of type '"..isa.."' not supported")
	end
	local _str
	if ltype == "string" then
		_str = "'"..value.."'"
	else
		_str = tostring(value)
	end

	self.value = value
	self.type = ltype
	self._str = _str
end

---@return FieldDef
function Lit:tofield()
	return t.FieldDef(self._str, self.type)
end

function Lit:__tostring()
	return self._str
end

assert(Lit:implements(lexpr))

return Lit
