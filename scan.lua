local lplan = require 'lplan'

---@class Scan:LogicalPlan
---@field path string path to the data source
---@field datasource DataSource
---@field projection string[] projection list
---@field _schema Schema schema of the data source
local Scan = lplan:extend('Scan')

---@param path string path to the data source
---@param datasource DataSource
---@param projection string[]
function Scan:_init(path, datasource, projection)
	self.path = path
	self.datasource = datasource
	self.projection = projection or {}

	local schema = datasource:schema()
	if not schema then
		error("failed to derive schema for "..path)
	end
	self._schema =  schema:select(self.projection)
end

function Scan:__tostring()
	if #self.projection == 0 then
		return ('Scan: %s; projection=None'):format(self.path)
	else
		return ('Scan: %s; projection=%s'):format(self.path, table.concat(self.projection, ", "))
	end
end

function Scan:children()
	return {}
end

function Scan:schema()
	return self._schema
end

assert(Scan:implements(lplan))

return Scan
