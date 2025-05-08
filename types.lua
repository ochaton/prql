local base = require 'base'
local table_new = require 'utils'.table_new

---@class FieldDef:Base,box.tuple.field_format
---@field name string
---@field type tuple_type
---@field is_nullable? boolean
---@field default? tuple_type
local FieldDef = base:extend('FieldDef')
function FieldDef:__tostring()
	if self.is_nullable then
		return "FieldDef("..self.name..", "..self.type..", NULL)"
	elseif self.default then
		return "FieldDef("..self.name..", "..self.type..", "..tostring(self.default)..")"
	else
		return "FieldDef("..self.name..", "..self.type..")"
	end
end

---@param name string|box.tuple.field_format
---@param isa? string
function FieldDef:_init(name, isa)
	if type(name) == "table" then
		local fmt = name
		self.name = assert(fmt.name, "name must be a string")
		self.type = assert(fmt.type, "type must be a string")
		self.is_nullable = fmt.is_nullable
		self.default = fmt.default
		if fmt.is_nullable == nil then
			self.is_nullable = false
		end
	else
		assert(type(name) == "string", "name must be a string")
		assert(type(isa) == "string", "type must be a string")
		self.name = name
		self.type = isa
	end
end

---@class Schema:Base
---@field format FieldDef[]
local Schema = base:extend('Schema')

---@param format FieldDef[]
function Schema:_init(format)
	assert(type(format) == "table", "format must be a table")
	local schema = {}
	for x, f in pairs(format) do
		if not FieldDef.as(f, "FieldDef") then
			f = FieldDef:new(f.name, f.type)
		end
		schema[x] = f
	end
	self.format = schema
	self._tuple_format = box.tuple.format.new(schema)
end

---Converts record to tuple
---@param record table<string, any>|any[]
---@return box.tuple<any,any>
function Schema:totuple(record)
	local t
	if #record == 0 then
		-- kv-like
		t = table_new(#self.format, 0)
		for i, field in ipairs(self.format) do
			local value = record[field.name]
			if type(value) == 'nil' then
				if field.is_nullable then
					t[i] = box.NULL
				else
					error("field '"..field.name.."' is not nullable")
				end
			else
				t[i] = value
			end
		end
	else
		-- array-like
		t = record
	end
	return box.tuple.new(t, { format = self._tuple_format })
end

---@param format FieldDef[]
---@param name string
---@return FieldDef?
local function find_name(format, name)
	for _, f in pairs(format) do
		if f.name == name then
			return f
		end
	end
	return nil
end

---@return Schema
function Schema:select(projection)
	assert(type(projection) == "table", "projection must be a table")
	if #projection == 0 then
		return self
	end
	local format = table_new(#projection, 0)
	for i, name in ipairs(projection) do
		local found = find_name(self.format, name)
		if not found then
			error("field "..name.." not found in schema")
		end
		format[i] = found
	end
	return Schema:new(format)
end

---@param name string
---@return FieldDef?
function Schema:find(name)
	assert(type(name) == "string", "name must be a string")
	return find_name(self.format, name)
end

function Schema:__tostring()
	local format = {}
	for _, f in pairs(self.format) do
		table.insert(format, "  "..tostring(f))
	end
	return "Schema: {\n"..table.concat(format, ",\n").."\n}"
end

---@class DataSource:Base
local DataSource = base:extend('DataSource', {'schema', 'scan'})

---@return fun.iterator<box.tuple<any,any>, nil>
function DataSource:scan()
	error("called on abstract DataSource")
end

---@return Schema
function DataSource:schema()
	error("called on abstract DataSource")
end

return {
	FieldDef = FieldDef,
	Schema = Schema,
	DataSource = DataSource,
}
