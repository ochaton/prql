
pcall(require, 'table.new')
local table_new = rawget(table, 'new') or function(_, _) return {} end

---Performs a shallow copy of a table.
---@generic T:table
---@param t T
---@return T
local function table_copy (t)
	local new_t = table_new(0, 8)
	for k, v in pairs(t) do new_t[k] = v end
	return new_t
end

---Builds new table_copy which copies only specified fields.
---@generic T:table
---@param only string[] list of field names
---@param n number number of fields
---@return fun(T): T
local function table_copy_only(only, n)
	---@param src T
	---@return T
	return function(src)
		local dst = table_new(0, n)
		for i = 1, n do
			local name = only[i]
			dst[name] = src[name]
		end
		return dst
	end
end


return {
	table_new = table_new,
	table_copy = table_copy,
	table_copy_only = table_copy_only,
}
