local base = require 'base'

---lexpr is metaclass for logical expressions
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

-------------------------------------------------------------

---Id is a class for identifier expression
---@class Id:lexpr
---@field name string
local Id = lexpr:extend('Id')

function Id:_init(name)
	assert(type(name) == "string", "name must be a string")
	self.name = name
end

function Id:__tostring() return '#'..self.name end

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

---Id constructor
---@param name string
---@return Id
local f = function(name)
	return Id:new(name)
end

-------------------------------------------------------------

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

	---@type tuple_type_name
	local ltype
	if isa == 'string' or isa == 'number' or isa == 'boolean' then
		-- ok
		ltype = isa
	elseif has_ffi and isa == "cdata" then
		if ffi.istype("int64_t", value) then
			ltype = "integer"
		elseif ffi.istype("uint64_t", value) then
			ltype = "unsigned"
		else
			local ctype = tostring(ffi.typeof(value))
			error("value '"..tostring(value).."' of cdata type '"..ctype.."' not supported")
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

---@param value any literal value
---@return Lit
local c = function(value)
	return Lit:new(value)
end

-------------------------------------------------------------

---@class BinaryExpr:lexpr
---@field name string name of the expression
---@field op string operator
---@field left lexpr left operand
---@field right lexpr right operand
local BinaryExpr = lexpr:extend('BinaryExpr')

---@param name string name of the expression
---@param op string operator
---@param l lexpr|number|string|boolean  left operand
---@param r lexpr|number|string|boolean right operand
function BinaryExpr:_init(name, op, l, r)
	local left, right
	if type(l) ~= "table" then
		left = Lit:new(l)
	else
		left = l
	end
	if type(r) ~= "table" then
		right = Lit:new(r)
	else
		right = r
	end
	self.name, self.op, self.left, self.right = name, op, left, right
end

function BinaryExpr:__tostring()
	return tostring(self.left).." "..self.op.." "..tostring(self.right)
end

---@class UnaryExpr:lexpr
---@field name string operator
---@field op string operator
---@field expr lexpr expression
local UnaryExpr = lexpr:extend('UnaryExpr')

---@param name string name of the expression
---@param op string operator
---@param expr lexpr expression
function UnaryExpr:_init(name, op, expr)
	assert(type(name) == "string", "name must be a string")
	assert(type(op) == "string", "op must be a string")
	assert(expr ~= nil, "expr cannot be nil")
	self.name, self.op, self.expr = name, op, expr
end

function UnaryExpr:__tostring() return self.op..tostring(self.expr) end

-------------------------------------------------------------

---@class Concat:BinaryExpr
local Concat = BinaryExpr:extend('Concat')

function Concat:_init(l, r) Concat.super._init(self, "concat", "..", l, r) end

---@param _ LogicalPlan
---@return FieldDef
function Concat:tofield(_)
	return t.FieldDef:new(tostring(self), "string")
end

---@return Concat
local function concat(l, r) return Concat:new(l, r) end

-------------------------------------------------------------

---@class BoolBinaryExpr:BinaryExpr
local BoolBinaryExpr = BinaryExpr:extend('BoolBinaryExpr')

function BoolBinaryExpr:tofield()
	return t.FieldDef:new(self.op, "boolean")
end

assert(BoolBinaryExpr:implements(lexpr))

---@class Eq:BoolBinaryExpr
local Eq = BoolBinaryExpr:extend('Eq') function Eq:_init(l, r) Eq.super._init(self, "eq", "==", l, r) end

---@class Ne:BoolBinaryExpr
local Ne = BoolBinaryExpr:extend('Ne') function Ne:_init(l, r) Ne.super._init(self, "ne", "~=", l, r) end

---@class Ge:BoolBinaryExpr
local Ge = BoolBinaryExpr:extend('Ge') function Ge:_init(l, r) Ge.super._init(self, "ge", ">=", l, r) end


---@class Gt:BoolBinaryExpr
local Gt = BoolBinaryExpr:extend('Gt') function Gt:_init(l, r) Gt.super._init(self, "gt", ">", l, r) end

---@class Lt:BoolBinaryExpr
local Lt = BoolBinaryExpr:extend('Lt') function Lt:_init(l, r) Lt.super._init(self, "lt", "<", l, r) end

---@class Le:BoolBinaryExpr
local Le = BoolBinaryExpr:extend('Le') function Le:_init(l, r) Le.super._init(self, "le", "<=", l, r) end

-------------------------------------------------------------

---@class And:BoolBinaryExpr
local And = BoolBinaryExpr:extend('And') function And:_init(l, r) And.super._init(self, "AND", "and", l, r) end

---@class Or:BoolBinaryExpr
local Or = BoolBinaryExpr:extend('Or') function Or:_init(l, r) Or.super._init(self, "OR", "or", l, r) end


---@class Not:UnaryExpr
local Not = UnaryExpr:extend('Not') function Not:_init(l) Not.super._init(self, "Not", l) end

function Not:tofield()
	return t.FieldDef:new(self.op, "boolean")
end

assert(Not:implements(lexpr))

-------------------------------------------------------------
-- Maths

---@class MathExpr:BinaryExpr
local MathExpr = BinaryExpr:extend('MathExpr')

---@param input LogicalPlan
---@return FieldDef
function MathExpr:tofield(input)
	return t.FieldDef:new(self.op, self.left:tofield(input).type)
end

assert(MathExpr:implements(lexpr))

---@class Add:MathExpr
local Add = MathExpr:extend('Add') function Add:_init(l, r) Add.super._init(self, "add", "+", l, r) end

---@class Sub:MathExpr
local Sub = MathExpr:extend('Sub') function Sub:_init(l, r) Sub.super._init(self, "sub", "-", l, r) end

---@class Mul:MathExpr
local Mul = MathExpr:extend('Mul') function Mul:_init(l, r) Mul.super._init(self, "mul", "*", l, r) end

---@class Div:MathExpr
local Div = MathExpr:extend('Div') function Div:_init(l, r) Div.super._init(self, "div", "/", l, r) end

---@class Mod:MathExpr
local Mod = MathExpr:extend('Mod') function Mod:_init(l, r) Mod.super._init(self, "mod", "%", l, r) end

---@class Pow:MathExpr
local Pow = MathExpr:extend('Pow') function Pow:_init(l, r) Pow.super._init(self, "pow", "^", l, r) end

---@class Unm:UnaryExpr
local Unm = UnaryExpr:extend('Unm') function Unm:_init(expr) Unm.super._init(self, "unm", "-", expr) end

function Unm:tofield(input)
	return t.FieldDef:new(self.op, self.expr:tofield(input).type)
end

Unm:implements(lexpr)

-------------------------------------------------------------
--- Aggregate expression

---@class AggregateExpr:lexpr
---@field name string name of the expression
---@field expr lexpr expression to aggregate
local AggregateExpr = lexpr:extend('AggregateExpr')

---@param name string
---@param expr lexpr
function AggregateExpr:_init(name, expr)
	self.name = name
	self.expr = expr
end

function AggregateExpr:__tostring()
	return ("%s(%s)"):format(self.name, self.expr)
end

---@param input LogicalPlan
---@return FieldDef
function AggregateExpr:tofield(input)
	return t.FieldDef:new(self.name, self.expr:tofield(input).type)
end

assert(AggregateExpr:implements(lexpr))

---@class Sum:AggregateExpr
local Sum = AggregateExpr:extend('Sum')
---@param expr lexpr
function Sum:_init(expr) AggregateExpr._init(self, 'sum', expr) end

---@class Avg:AggregateExpr
local Avg = AggregateExpr:extend('Avg')

---@param expr lexpr
function Avg:_init(expr) AggregateExpr._init(self, 'avg', expr) end

---@class Min:AggregateExpr
local Min = AggregateExpr:extend('Min')

---@param expr lexpr
function Min:_init(expr) AggregateExpr._init(self, 'min', expr) end

---@class Max:AggregateExpr
local Max = AggregateExpr:extend('Max')

---@param expr lexpr
function Max:_init(expr) AggregateExpr._init(self, 'max', expr) end

---@class Count:AggregateExpr
local Count = AggregateExpr:extend('Count')

---@param expr lexpr
function Count:_init(expr) AggregateExpr._init(self, "count", expr) end

function Count:tofield(_)
	return t.FieldDef:new("count", 'unsigned')
end

---@param expr lexpr
---@return Avg
local function avg(expr) return Avg:new(expr) end

---@param expr lexpr
---@return Sum
local function sum(expr) return Sum:new(expr) end

---@param expr lexpr
---@return Count
local function count(expr) return Count:new(expr) end

---@param expr lexpr
---@return Min
local function min(expr) return Min:new(expr) end

---@param expr lexpr
---@return Max
local function max(expr) return Max:new(expr) end

-------------------------------------------------------------

---@class Alias:lexpr
---@field expr lexpr expression to alias
---@field name string alias name
local Alias = lexpr:extend('Alias')

---@param expr lexpr
---@param alias string
function Alias:_init(expr, alias)
	assert(type(alias) == "string", "alias must be a string")
	self.expr = expr
	self.name = alias
end

---@param input LogicalPlan
---@return FieldDef
function Alias:tofield(input)
	return t.FieldDef:new(self.name, self.expr:tofield(input).type)
end

function Alias:__tostring()
	return ("%s as %s"):format(tostring(self.expr), self.name)
end

assert(Alias:implements(lexpr))

-------------------------------------------------------------

---@return Unm
function lexpr:unm() return Unm:new(self) end
---@return Add
function lexpr:add(other) return Add:new(self, other) end
---@return Sub
function lexpr:sub(other) return Sub:new(self, other) end
---@return Mul
function lexpr:mul(other) return Mul:new(self, other) end
---@return Div
function lexpr:div(other) return Div:new(self, other) end
---@return Mod
function lexpr:mod(other) return Mod:new(self, other) end
---@return Pow
function lexpr:pow(other) return Pow:new(self, other) end
---@return Ge
function lexpr:ge(other) return Ge:new(self, other) end
---@return Gt
function lexpr:gt(other) return Gt:new(self, other) end
---@return Le
function lexpr:le(other) return Le:new(self, other) end
---@return Lt
function lexpr:lt(other) return Lt:new(self, other) end
---@return Eq
function lexpr:eq(other) return Eq:new(self, other) end
---@return Ne
function lexpr:ne(other) return Ne:new(self, other) end
---@return And
function lexpr:And(other) return And:new(self, other) end
---@return Or
function lexpr:Or(other) return Or:new(self, other) end
---@return Not
function lexpr:Not() return Not:new(self) end
---@return Concat
function lexpr:concat(other) return Concat:new(self, other) end

return {
	lexpr = lexpr,
	Id = Id,
	Lit = Lit,

	f = f,
	c = c,

	concat = concat,
	Concat = Concat,

	Eq = Eq,
	eq = lexpr.eq,
	Ne = Ne,
	ne = lexpr.ne,
	Ge = Ge,
	ge = lexpr.ge,
	Gt = Gt,
	gt = lexpr.gt,
	Lt = Lt,
	lt = lexpr.lt,
	Le = Le,
	le = lexpr.le,

	And = And,
	AND = lexpr.And,
	Or = Or,
	OR = lexpr.Or,
	Not = Not,
	NOT = lexpr.Not,

	Add = Add,
	add = lexpr.add,
	Sub = Sub,
	sub = lexpr.sub,
	Mul = Mul,
	mul = lexpr.mul,
	Div = Div,
	div = lexpr.div,
	Mod = Mod,
	mod = lexpr.mod,
	Pow = Pow,
	pow = lexpr.pow,
	Unm = Unm,
	unm = lexpr.unm,

	Sum = Sum,
	sum = sum,
	Avg = Avg,
	avg = avg,
	Min = Min,
	min = min,
	Max = Max,
	max = max,
	Count = Count,
	count = count,

	Alias = Alias,
}
