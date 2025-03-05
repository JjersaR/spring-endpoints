local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local parser = require("spring_endpoints.parser")

local function open_file(entry)
	vim.cmd("edit " .. entry.file)
	vim.fn.search(entry.path, "w")
end

local function search_endpoints()
	local endpoints = parser.find_endpoints(vim.fn.getcwd())

	local seen_paths = {} -- Para evitar duplicados
	-- Filtrar los endpoints que NO contengan "[REQUEST]"
	local filtered_endpoints = {}
	for _, ep in ipairs(endpoints) do
		if not ep.path:match("^REQUEST") and not seen_paths[ep.path] then
			table.insert(filtered_endpoints, ep)
			seen_paths[ep.path] = true
		end
	end

	pickers
		.new({}, {
			prompt_title = "Spring Boot Endpoints",
			prompt_prefix = " ",
			finder = finders.new_table({
				results = filtered_endpoints,
				entry_maker = function(entry)
					return {
						value = entry,
						display = string.format("[%s] %s", entry.method, entry.path),
						ordinal = entry.method .. " " .. entry.path,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry().value
					actions.close(prompt_bufnr)
					open_file(selection)
				end)
				return true
			end,
		})
		:find()
end

return {
	search_endpoints = search_endpoints,
}
