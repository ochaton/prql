local exprs = require 'exprs'
local f = exprs.f
local lt, le, ge, gt = exprs.lt, exprs.le, exprs.ge, exprs.gt
local ne, eq = exprs.ne, exprs.eq
local AND, OR = exprs.AND, exprs.OR

---@param str string
---@return lexpr
local e = function(str) end



-- local e = Eq(f"a", f"b")
-- print(e)
-- prin)
-- print(e:tofield())

-- local x = Not(f"a")
-- print(x)
-- prin)
-- print(x:tofield())

-- print("Not", Not)
-- for k, v in pairs(Not) do
-- 	print(k, v)
-- end

-- print("Field", Field)
-- for k, v in pairs(Field) do
-- 	print(k, v)
-- end

-- print("Field.__add", Field.__add)
-- print("Not.__add", Not.__add)

print("--- testing ---")

local a = f"a"
print(a)

local b = f"b"
print(b)

local x = a + b --[[@as lexpr]]
print(x)

local y = f"a" + 4
print(y)

local z = 4 / f"a"
print(z)

local w = f"a" % f"b"
print(w)

local v = f"a" % 3
print(v)

local u = f"a" ^ 4
print(u)

local t = 4 ^ f"a"
print(t)

-- We need to do smthing with cmp
local cmp = lt(f"a", "4")
print(cmp)

local lt = f"a":lt("4")
print(lt)

local cmp2 = le(f"a", 4)
print(cmp2)

local cmp3 = ge(f"a", 4)
print(cmp3)

local bool = AND(gt(f"a", 5), ge(f"b", 6))
print(bool)

local maths = AND(gt(1 + f"a" + f"b", 0), ne(f"b" - 2, 0))
print(maths)

-- (1 + a + b) > 0 and (b - 2) ~= 0

e[[ (1+a+b)>0 and (b-2)~=0 ]]

local cmplx = (1+f"a"+f"b"):gt(0):And((f"b"-2):ne(0))
print(cmplx)

