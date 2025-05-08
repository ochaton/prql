local base = require 'base'
local phys = require 'phys'
local expr = require 'expr'
local exec = require 'exec'
local t = require 'types'

local op2expr = {
	['=='] = expr.PhyEqExpr,
	['!='] = expr.PhyNeExpr,
	['<'] = expr.PhyLtExpr,
	['<='] = expr.PhyLeExpr,
	['>'] = expr.PhyGtExpr,
	['>='] = expr.PhyGeExpr,
	['+'] = expr.PhyAddExpr,
	['-'] = expr.PhySubExpr,
	['*'] = expr.PhyMulExpr,
	['/'] = expr.PhyDivExpr,
	['%'] = expr.PhyModExpr,
	['and'] = expr.PhyAndExpr,
	['or'] = expr.PhyOrExpr
}

---@param lexpr lexpr
---@param logical_plan LogicalPlan
---@return Expr
local function to_physical_expr(lexpr, logical_plan)
	if false then
	elseif lexpr:as('Id') then
		---@cast lexpr Id
		local fd = lexpr:tofield(logical_plan)
		return expr.IdExpr:new(fd.name)
	elseif lexpr:as('Lit') then
		---@cast lexpr Lit
		return expr.LitExpr:new(lexpr.type, lexpr.value)
	elseif lexpr:as('AliasExpr') then
		---@cast lexpr Alias
		return to_physical_expr(expr.expr, logical_plan)
	elseif lexpr:as('BinaryExpr') then
		---@cast lexpr BinaryExpr
		local left = to_physical_expr(lexpr.left, logical_plan)
		local right = to_physical_expr(lexpr.right, logical_plan)
		local phyexpr = op2expr[lexpr.op]
		if phyexpr == nil then
			error('unknown operator: '..lexpr.op)
		end
		return phyexpr:new(left, right)
	elseif lexpr:as('AggregateExpr') then
		---@cast lexpr AggregateExpr
		if lexpr.name == 'sum' then
			return expr.SumExpr:new(to_physical_expr(lexpr.expr, logical_plan))
		elseif lexpr.name == 'avg' then
			return expr.AvgExpr:new(to_physical_expr(lexpr.expr, logical_plan))
		elseif lexpr.name == 'count' then
			return expr.CountExpr:new(to_physical_expr(lexpr.expr, logical_plan))
		elseif lexpr.name == 'max' then
			return expr.MaxExpr:new(to_physical_expr(lexpr.expr, logical_plan))
		elseif lexpr.name == 'min' then
			return expr.MinExpr:new(to_physical_expr(lexpr.expr, logical_plan))
		else
			error('unknown aggregate function: '..lexpr.name)
		end
	elseif lexpr:as('Alias') then
		---@cast lexpr Alias
		return to_physical_expr(lexpr.expr, logical_plan)
	end

	error('unknown expression type: '..tostring(lexpr))
end

---@param logical_plan LogicalPlan
---@return PhysicalPlan
local function to_physical_plan(logical_plan)
	if false then
	elseif logical_plan:as('Scan') then
		---@cast logical_plan Scan
		return exec.ScanExec:new(logical_plan.datasource, logical_plan.projection)
	elseif logical_plan:as('Projection') then
		---@cast logical_plan Projection
		local input = to_physical_plan(logical_plan.input)
		local exprs = {}
		local schema = {}
		for _, lexpr in ipairs(logical_plan.exprs) do
			table.insert(exprs, to_physical_expr(lexpr, logical_plan.input))
			table.insert(schema, lexpr:tofield(logical_plan.input))
		end
		return exec.ProjectionExec:new(input, t.Schema:new(schema), exprs)
	elseif logical_plan:as('Filter') then
		---@cast logical_plan Filter
		local input = to_physical_plan(logical_plan.input)
		local filter_expr = to_physical_expr(logical_plan.expr, logical_plan.input)
		return exec.FilterExec:new(input, filter_expr)
	elseif logical_plan:as('Aggregate') then
		---@cast logical_plan Aggregate
		local input = to_physical_plan(logical_plan.input)
		local groupby = {}
		local aggregates = {}
		for _, lexpr in ipairs(logical_plan.group_by) do
			table.insert(groupby, to_physical_expr(lexpr, logical_plan.input))
		end
		for _, lexpr in ipairs(logical_plan.aggregates) do
			table.insert(aggregates, to_physical_expr(lexpr, logical_plan.input))
		end
		return exec.HashAggregateExec:new(input, groupby, aggregates, logical_plan:schema())
	elseif logical_plan:as('Sort') then
		---@cast logical_plan Sort
		local input = to_physical_plan(logical_plan.input)
		local order_by = {}
		for _, lexpr in ipairs(logical_plan.order) do
			local dir = 'asc'
			if lexpr:as('Unm') then -- unary minus in order just means descending
				---@cast lexpr Unm
				dir = 'desc'
				lexpr = lexpr.expr
			end
			table.insert(order_by, expr.PhySortExpr:new(to_physical_expr(lexpr, logical_plan.input), dir))
		end
		return exec.SortExec:new(input, order_by)
	elseif logical_plan:as('Limit') then
		---@cast logical_plan Limit
		local input = to_physical_plan(logical_plan.input)
		return exec.LimitExec:new(input, logical_plan.offset, logical_plan.limit)
	end
	error('unknown logical plan type: '..tostring(logical_plan))
end

---@param logical_plan LogicalPlan
---@return PhysicalPlan
local function create_physical_plan(logical_plan)
	local ok, err = pcall(to_physical_plan, logical_plan)
	if not ok then
		-- we just reraise the error, and drop the stack trace
		error(err, 2)
	end
	---@cast err PhysicalPlan
	return err
end

return {
	create_physical_plan = create_physical_plan,
	create_physical_expr = to_physical_expr,
}
