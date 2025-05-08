local setmetatable, type, pairs, rawget, assert = setmetatable, type, pairs, rawget, assert

local copy do
	pcall(require, 'table.new')
	local table_new = rawget(table, 'new') or function(_, _) return {} end

	function copy(t)
		local new_t = table_new(0, 8)
		for k, v in pairs(t) do new_t[k] = v end
		return new_t
	end
end

---@class Base
---@field super Base parent class
---@field private __type string name of the class
---@field public is fun():Base returns class itself
local base = { __type = "Base" }
base.__index = base

---Creates a subclass of the class.
---@param name string name of the subclass
---@param proto string[]? list of methods to be implemented in subclasses
---@return Base
function base:extend(name, proto)
	assert(type(name) == 'string', 'name must be a string')
	local child = setmetatable(copy(self), self)
	child.__type = name
	child.__index = child
	child.__proto = proto
	child.super = self
	child.is = function() return child end
	return child
end

---Construct a new instance of the class.
---@generic T
---@param self T
---@return T
function base.new(self, ...)
	local obj = setmetatable({}, self)
	obj:_init(...)
	return obj
end

---Returns class-ancestor identified by name
---@param t string|Base
---@return Base?
function base:as(t)
	if type(t) ~= 'string' then t = t.__type end
	while type(self) == 'table' and self.__type ~= t do
		self = self.super
	end
	return self
end

---Checks if the class implements all methods of the interface.
---@param interface Base
---@return boolean, string? error_message
function base:implements(interface)
	if interface.__proto == nil then return true end
	for _, name in pairs(interface.__proto) do
		if self[name] == nil or self[name] == interface[name] then
			return false, ("missing method '%s:%s' for '%s'"):format(
				self.__type, name, interface.__type)
		end
	end
	return true
end

---User-defined constructor of the class.
function base._init(...) end
return base
