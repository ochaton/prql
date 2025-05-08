local lplan = require 'lplan'

---@class Limit:LogicalPlan
---@field offset integer
---@field limit integer?
local Limit = lplan:extend('Limit')

---@param plan LogicalPlan
---@param limit integer?
---@param offset integer?
function Limit:_init(plan, limit, offset)
	self.plan = plan
	if not limit and not offset then
		error("Limit and Offset must be provided")
	end
	self.offset = offset or 0
	self.limit = limit
end

function Limit:__tostring()
	if self.offset > 0 then
		if self.limit then
			return ("Limit: %d, Offset: %d"):format(self.limit, self.offset)
		else
			return ("Offset: %d"):format(self.offset)
		end
	elseif self.limit then
		return ("Limit: %d"):format(self.limit)
	end
end

function Limit:children()
	return {self.plan}
end

function Limit:schema()
	return self.plan:schema()
end

assert(Limit:implements(lplan))

return Limit