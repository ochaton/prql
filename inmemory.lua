local fun = require 'fun'
local t = require 'types'

---@class Inmemory:DataSource
---@field _records table[] list of records
---@field _schema Schema schema of the data source
---@field _tuple_format box.tuple.format tuple format of the data source
local Inmemory = t.DataSource:extend('Inmemory')

---@param records table[] list of records
---@param format box.tuple.field_format[] schema of the records
function Inmemory:_init(records, format)
	assert(type(records) == 'table', 'records must be a table')
	self._records = records
	self._schema = t.Schema:new(format)
end

---@return fun.iterator<box.tuple<any,any>,nil>
function Inmemory:scan()
	local iterator = fun.map(function(r)
		return self._schema:totuple(r)
	end, self._records)
	return iterator
end

function Inmemory:schema()
	return self._schema
end

assert(Inmemory:implements(t.DataSource))

return Inmemory
