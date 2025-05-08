local lexpr = require 'lexpr'
local f = lexpr.f
local yaml = require 'yaml'

local avg, sum = lexpr.avg, lexpr.sum

local inmemory = require 'inmemory'

---@type Inmemory
local rt = inmemory:new({
	{ id = 1, first_name = 'John', last_name = 'Doe', age = 30, salary = 50000, state = 'NY' },
	{ id = 2, first_name = 'Jane', last_name = 'Smith', age = 25, salary = 60000, state = 'CA' },
	{ id = 3, first_name = 'Bob', last_name = 'Johnson', age = 40, salary = 70000, state = 'TX' },
	{ id = 4, first_name = 'Alice', last_name = 'Williams', age = 35, salary = 80000, state = 'FL' },
	{ id = 5, first_name = 'Charlie', last_name = 'Brown', age = 28, salary = 90000, state = 'WA' },
	{ id = 6, first_name = 'David', last_name = 'Jones', age = 45, salary = 100000, state = 'NY' },
	{ id = 7, first_name = 'Eve', last_name = 'Davis', age = 32, salary = 110000, state = 'CA' },
	{ id = 8, first_name = 'Frank', last_name = 'Miller', age = 50, salary = 120000, state = 'TX' },
	{ id = 9, first_name = 'Grace', last_name = 'Wilson', age = 38, salary = 130000, state = 'FL' },
	{ id = 10, first_name = 'Hank', last_name = 'Moore', age = 29, salary = 140000, state = 'WA' },
	{ id = 11, first_name = 'Ivy', last_name = 'Taylor', age = 42, salary = 150000, state = 'NY' },
	{ id = 12, first_name = 'Jack', last_name = 'Anderson', age = 36, salary = 160000, state = 'CA' },
	{ id = 13, first_name = 'Kathy', last_name = 'Thomas', age = 27, salary = 170000, state = 'TX' },
	{ id = 14, first_name = 'Leo', last_name = 'Jackson', age = 39, salary = 180000, state = 'FL' },
	{ id = 15, first_name = 'Mia', last_name = 'White', age = 31, salary = 190000, state = 'WA' },
	{ id = 16, first_name = 'Nina', last_name = 'Harris', age = 46, salary = 200000, state = 'NY' },
	{ id = 17, first_name = 'Oscar', last_name = 'Martin', age = 33, salary = 210000, state = 'CA' },
	{ id = 18, first_name = 'Paul', last_name = 'Thompson', age = 48, salary = 220000, state = 'TX' },
	{ id = 19, first_name = 'Quinn', last_name = 'Garcia', age = 37, salary = 230000, state = 'FL' },
	{ id = 20, first_name = 'Rita', last_name = 'Martinez', age = 30, salary = 240000, state = 'WA' },
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

local plan = require 'plan'

local Scan = plan.Scan
local Filter = plan.Filter
local Projection = plan.Projection

local scan = Scan:new('employee', rt, {})

local filterExpr = f"state":eq("NY"):Or(f"age":gt(30))
---@type Filter
local filter = Filter:new(scan, filterExpr)

local projection = { f"id", f"first_name", f"last_name", f"age", f"salary" }
---@type Projection
local p = Projection:new(filter, projection)

print(p:pretty())
print(p:schema())

local planner = require 'planner'

local exec = planner.create_physical_plan(p)
print(exec:pretty())
print(exec:schema())

local result = {
	rows = exec:execute():totable(),
	format = exec:schema().format,
}

print(yaml.encode(result))

local ql = require 'ql'

local q = ql.from('employee', rt)
	:filter(f"age":gt(25))
	:derive {
		gross_salary = f"salary",
	}
	:derive {
		gross_cost = f"gross_salary"
	}
	:filter(f"gross_cost":gt(0))
	:group {
		{ f"state" }, function(g)
			return g:aggregate {
				avg_gross_salary = avg(f"gross_salary"),
				sum_gross_cost = sum(f"gross_cost"),
			}
		end
	}
	:filter(f"sum_gross_cost":gt(60*1000))
	:sort{ f"sum_gross_cost", -f"state" }
	:take(1, 10)

print(q.plan:pretty())
print(q.plan:schema())

p = planner.create_physical_plan(q.plan)
print(p:pretty())
print(p:schema())

result = {
	format = p:schema().format,
	rows = p:execute():totable(),
}
print(yaml.encode(result))