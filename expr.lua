local base = require 'base'

---interface for expression
---@class Expr:Base
local Expr = base:extend('Expr', {'eval', '__tostring'})

---@param input box.tuple<any,any>
---@return tuple_type tuple_field
function Expr:eval(input) error('called on abstract expr') end

---@class IdExpr:Expr
---@field name string
local IdExpr = Expr:extend('IdExpr')

function IdExpr:_init(name)
	assert(type(name) == 'string', "name must be a string")
	self.name = name
end

---@param input box.tuple<any,any>
---@return tuple_type tuple_field
function IdExpr:eval(input) return input[self.name] end
function IdExpr:__tostring() return '#'..self.name end

assert(IdExpr:implements(Expr))

---@class LitExpr:Expr
---@field type tuple_type_name
---@field value tuple_type
local LitExpr = Expr:extend('LitExpr')

---@param isa tuple_type_name
---@param value tuple_type
function LitExpr:_init(isa, value)
	self.type = isa
	self.value = value
end

function LitExpr:__tostring() return ('%s(%s)'):format(self.type, self.value) end

---@param input box.tuple<any,any>
---@return tuple_type tuple_field
function LitExpr:eval(input) return self.value end

assert(LitExpr:implements(Expr))

---@class PhyBinaryExpr:Expr
---@field left Expr
---@field right Expr
local PhyBinaryExpr = Expr:extend('PhyBinaryExpr', {'evaluate', '__tostring'})

function PhyBinaryExpr:_init(left, right)
	assert(Expr.as(left, Expr), "left must be an Expr")
	assert(Expr.as(right, Expr), "right must be an Expr")
	self.left = left
	self.right = right
end

---@param input box.tuple<any,any>
function PhyBinaryExpr:eval(input)
	local left = self.left:eval(input)
	local right = self.right:eval(input)
	if type(left) ~= type(right) then
		error('type mismatch: '..type(left)..' != '..type(right))
	end
	return self:evaluate(left, right)
end

---@param left tuple_type
---@param right tuple_type
---@return tuple_type
function PhyBinaryExpr:evaluate(left, right)
	error('called on abstract PhyBinaryExpr')
end

---@class PhyEqExpr:PhyBinaryExpr
local PhyEqExpr = PhyBinaryExpr:extend('PhyEqExpr')
function PhyEqExpr:evaluate(left, right) return left == right end
function PhyEqExpr:__tostring() return ('%s == %s'):format(tostring(self.left), tostring(self.right)) end
assert(PhyEqExpr:implements(PhyBinaryExpr))

---@class PhyNeExpr:PhyBinaryExpr
local PhyNeExpr = PhyBinaryExpr:extend('PhyNeExpr')
function PhyNeExpr:evaluate(left, right) return left ~= right end
function PhyNeExpr:__tostring() return ('%s ~= %s'):format(tostring(self.left), tostring(self.right)) end
assert(PhyNeExpr:implements(PhyBinaryExpr))

---@class PhyLtExpr:PhyBinaryExpr
local PhyLtExpr = PhyBinaryExpr:extend('PhyLtExpr')
function PhyLtExpr:evaluate(left, right) return left < right end
function PhyLtExpr:__tostring() return ('%s < %s'):format(tostring(self.left), tostring(self.right)) end
assert(PhyLtExpr:implements(PhyBinaryExpr))

---@class PhyLeExpr:PhyBinaryExpr
local PhyLeExpr = PhyBinaryExpr:extend('PhyLeExpr')
function PhyLeExpr:evaluate(left, right) return left <= right end
function PhyLeExpr:__tostring() return ('%s <= %s'):format(tostring(self.left), tostring(self.right)) end
assert(PhyLeExpr:implements(PhyBinaryExpr))

---@class PhyGtExpr:PhyBinaryExpr
local PhyGtExpr = PhyBinaryExpr:extend('PhyGtExpr')
function PhyGtExpr:evaluate(left, right) return left > right end
function PhyGtExpr:__tostring() return ('%s > %s'):format(tostring(self.left), tostring(self.right)) end
assert(PhyGtExpr:implements(PhyBinaryExpr))

---@class PhyGeExpr:PhyBinaryExpr
local PhyGeExpr = PhyBinaryExpr:extend('PhyGeExpr')
function PhyGeExpr:evaluate(left, right) return left >= right end
function PhyGeExpr:__tostring() return ('%s >= %s'):format(tostring(self.left), tostring(self.right)) end
assert(PhyGeExpr:implements(PhyBinaryExpr))

---@class PhyAndExpr:PhyBinaryExpr
local PhyAndExpr = PhyBinaryExpr:extend('PhyAndExpr')
function PhyAndExpr:evaluate(left, right) return left ~= nil and left ~= false and right ~= nil and right ~= false end
function PhyAndExpr:__tostring() return ('%s and %s'):format(tostring(self.left), tostring(self.right)) end
assert(PhyAndExpr:implements(PhyBinaryExpr))

---@class PhyOrExpr:PhyBinaryExpr
local PhyOrExpr = PhyBinaryExpr:extend('PhyOrExpr')
function PhyOrExpr:evaluate(left, right) return (left ~= nil and left ~= false) or (right ~= nil and right ~= false) end
function PhyOrExpr:__tostring() return ('%s or %s'):format(tostring(self.left), tostring(self.right)) end
assert(PhyOrExpr:implements(PhyBinaryExpr))

---@class AddExpr:PhyBinaryExpr
local AddExpr = PhyBinaryExpr:extend('AddExpr')
function AddExpr:evaluate(left, right) return left + right end
function AddExpr:__tostring() return ('%s + %s'):format(tostring(self.left), tostring(self.right)) end
assert(AddExpr:implements(PhyBinaryExpr))

---@class SubExpr:PhyBinaryExpr
local SubExpr = PhyBinaryExpr:extend('SubExpr')
function SubExpr:evaluate(left, right) return left - right end
function SubExpr:__tostring() return ('%s - %s'):format(tostring(self.left), tostring(self.right)) end
assert(SubExpr:implements(PhyBinaryExpr))

---@class MulExpr:PhyBinaryExpr
local MulExpr = PhyBinaryExpr:extend('MulExpr')
function MulExpr:evaluate(left, right) return left * right end
function MulExpr:__tostring() return ('%s * %s'):format(tostring(self.left), tostring(self.right)) end
assert(MulExpr:implements(PhyBinaryExpr))

---@class DivExpr:PhyBinaryExpr
local DivExpr = PhyBinaryExpr:extend('DivExpr')
function DivExpr:evaluate(left, right) return left / right end
function DivExpr:__tostring() return ('%s / %s'):format(tostring(self.left), tostring(self.right)) end
assert(DivExpr:implements(PhyBinaryExpr))

---@class ModExpr:PhyBinaryExpr
local ModExpr = PhyBinaryExpr:extend('ModExpr')
function ModExpr:evaluate(left, right) return left % right end
function ModExpr:__tostring() return ('%s %% %s'):format(tostring(self.left), tostring(self.right)) end
assert(ModExpr:implements(PhyBinaryExpr))

---@class AggrExpr:Expr
---@field expr Expr
---@field accumulator Accumulator
local AggrExpr = Expr:extend('AggrExpr', {'__tostring'})

---@param expr Expr
function AggrExpr:_init(expr)
	self.expr = expr
end

function AggrExpr:eval(input)
	return self.expr:eval(input)
end

function AggrExpr:newaccumulator()
	return self.accumulator:new()
end

function AggrExpr:__tostring()
	error('called on abstract AggrExpr')
end

assert(AggrExpr:implements(Expr))

---@class Accumulator:Base
---@field state tuple_type
local Accumulator = base:extend('Accumulator', {'accumulate'})

---@param initial tuple_type
function Accumulator:_init(initial)
	self.state = initial
end

---@return tuple_type
function Accumulator:final()
	return self.state
end

---@param value tuple_type
function Accumulator:accumulate(value)
	error('called on abstract Accumulator')
end

---@class Summator:Accumulator
local Summator = Accumulator:extend('Summator')

function Summator:accumulate(value)
	if self.state == nil then
		self.state = value
	else
		self.state = self.state + value
	end
end

---@class Counter:Accumulator
local Counter = Accumulator:extend('Counter')

function Counter:accumulate(value)
	self.state = (self.state or 0) + 1
end

---@class Minimizer:Accumulator
local Minimizer = Accumulator:extend('Minimizer')

function Minimizer:accumulate(value)
	if self.state == nil then
		self.state = value
	elseif self.state > value then
		self.state = value
	end
end

---@class Maximizer:Accumulator
local Maximizer = Accumulator:extend('Maximizer')

function Maximizer:accumulate(value)
	if self.state == nil then
		self.state = value
	elseif self.state < value then
		self.state = value
	end
end

---@class SumExpr:AggrExpr
local SumExpr = AggrExpr:extend('SumExpr')

function SumExpr:_init(expr)
	self.accumulator = Summator
	AggrExpr._init(self, expr)
end

function SumExpr:__tostring()
	return ('Sum(%s)'):format(tostring(self.expr))
end

assert(SumExpr:implements(AggrExpr))

---@class CountExpr:AggrExpr
local CountExpr = AggrExpr:extend('CountExpr')

function CountExpr:_init(expr)
	self.accumulator = Counter
	AggrExpr._init(self, expr)
end

function CountExpr:__tostring()
	return ('Count(%s)'):format(tostring(self.expr))
end

assert(CountExpr:implements(AggrExpr))

---@class MinExpr:AggrExpr
local MinExpr = AggrExpr:extend('MinExpr')

function MinExpr:_init(expr)
	self.accumulator = Minimizer
	AggrExpr._init(self, expr)
end

function MinExpr:__tostring()
	return ('Min(%s)'):format(tostring(self.expr))
end

---@class MaxExpr:AggrExpr
local MaxExpr = AggrExpr:extend('MaxExpr')
function MaxExpr:_init(expr)
	self.accumulator = Maximizer
	AggrExpr._init(self, expr)
end

function MaxExpr:__tostring()
	return ('Max(%s)'):format(tostring(self.expr))
end

---@class AvgAccumulator:Accumulator
local AvgAccumulator = Accumulator:extend('AvgAccumulator')

function AvgAccumulator:_init(initial)
	self.sum = Summator:new(initial)
	self.count = Counter:new()
end

function AvgAccumulator:accumulate(value)
	self.sum:accumulate(value)
	self.count:accumulate(value)
end

function AvgAccumulator:final()
	if self.count:final() == 0 then
		return nil
	end
	return self.sum:final() / self.count:final()
end

---@class AvgExpr:AggrExpr
local AvgExpr = AggrExpr:extend('AvgExpr')

function AvgExpr:_init(expr)
	self.accumulator = AvgAccumulator
	AggrExpr._init(self, expr)
end

function AvgAccumulator:__tostring()
	return ('AvgAccumulator(%s, %s)'):format(tostring(self.sum), tostring(self.count))
end

return {
	Expr = Expr,
	IdExpr = IdExpr,
	LitExpr = LitExpr,
	PhyBinaryExpr = PhyBinaryExpr,
	AddExpr = AddExpr,
	SubExpr = SubExpr,
	MulExpr = MulExpr,
	DivExpr = DivExpr,
	ModExpr = ModExpr,

	PhyOrExpr = PhyOrExpr,
	PhyAndExpr = PhyAndExpr,
	PhyEqExpr = PhyEqExpr,
	PhyNeExpr = PhyNeExpr,
	PhyLtExpr = PhyLtExpr,
	PhyLeExpr = PhyLeExpr,
	PhyGtExpr = PhyGtExpr,
	PhyGeExpr = PhyGeExpr,

	AggrExpr = AggrExpr,
	SumExpr = SumExpr,
	CountExpr = CountExpr,
	MinExpr = MinExpr,
	MaxExpr = MaxExpr,
	AvgExpr = AvgExpr,
}
