local exprs = require 'exprs'
local f = exprs.f
local c = exprs.c
local json = require 'json'
local yaml = require 'yaml'

local avg, min, max, sum, count = exprs.avg, exprs.min, exprs.max, exprs.sum, exprs.count

local inmemory = require 'inmemory'

---@type Inmemory
local rt = inmemory:new({
	{ id = 1, first_name = 'John', last_name = 'Doe', age = 30, salary = 50000, state = 'NY' },
	{ id = 2, first_name = 'Jane', last_name = 'Smith', age = 25, salary = 60000, state = 'CA' },
	{ id = 3, first_name = 'Bob', last_name = 'Johnson', age = 40, salary = 70000, state = 'TX' },
	{ id = 4, first_name = 'Alice', last_name = 'Williams', age = 35, salary = 80000, state = 'FL' },
	{ id = 5, first_name = 'Charlie', last_name = 'Brown', age = 28, salary = 90000, state = 'WA' },
}, {
	{ name = 'id', type = 'unsigned' },
	{ name = 'first_name', type = 'string' },
	{ name = 'last_name', type = 'string' },
	{ name = 'age', type = 'unsigned' },
	{ name = 'salary', type = 'unsigned' },
	{ name = 'state', type = 'string' },
})

rt:scan():each(function(t)
	-- local json = require 'json'
	-- print(t, json.encode(t:tomap()), json.encode(t:format()))
end)

local Scan = require 'scan'
local Filter = require 'filter'
local Projection = require 'projection'

local scan = Scan:new('employee', rt, {})

local filterExpr = f"state":eq("NY"):Or(f"age":gt(30))
---@type Filter
local filter = Filter:new(scan, filterExpr)

local projection = { f"id", f"first_name", f"last_name", f"age", f"salary" }
---@type Projection
local plan = Projection:new(filter, projection)

print(plan:pretty())
print(plan:schema())

local planner = require 'planner'

local exec = planner.create_physical_plan(plan)
print(exec:pretty())
print(exec:schema())

local result = {
	rows = exec:execute():totable(),
	format = exec:schema().format,
}

print(yaml.encode(result, { indent = true }))

local ql = require 'ql'

local q = ql.from('employee', rt)
	:filter(f"age":gt(25))
	:derive {
		gross_salary = f"salary" + f"tax":def(0),
	}
	:derive {
		gross_cost = f"gross_salary" + f"benefits"
	}
	:filter(f"gross_cost":gt(0))
	:group {
		{ f"state" }, function(g)
			return g:aggregate {
				avg(f"gross_salary"),
				sum_gross_cost = sum(f"gross_cost"),
			}
		end
	}
	:filter(f"sum_gross_cost":gt(100*1000))
	:derive { id = f"first_name" .. "_" .. f"last_name" }
	:sort{ f"sum_gross_cost", -f"state" }
	:take(1, 10)

-- print(q.plan:pretty())
-- print(q.plan:schema())
