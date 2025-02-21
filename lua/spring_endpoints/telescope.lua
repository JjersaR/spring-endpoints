local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local parser = require("spring_endpoints.parser")

-- Métodos HTTP válidos
local http_methods = { "GET", "POST", "PUT", "DELETE", "PATCH" }
local filter_options = { "Sí", "No" }

-- Función para abrir el archivo en la línea correcta
local function open_file(entry)
	vim.cmd("edit " .. entry.file)
	vim.fn.search(entry.path, "w")
end

-- Buscar endpoints, opcionalmente filtrando por método
local function search_endpoints(method)
	local endpoints = parser.find_endpoints(vim.fn.getcwd())

	-- Filtrar si se eligió un método
	if method then
		local filtered = {}
		for _, ep in ipairs(endpoints) do
			if ep.method == method then
				table.insert(filtered, ep)
			end
		end
		endpoints = filtered
	end

	if #endpoints == 0 then
		print("No se encontraron endpoints.")
		return
	end

	pickers
		.new({}, {
			prompt_title = method and ("Endpoints " .. method) or "Todos los Endpoints",
			finder = finders.new_table({
				results = endpoints,
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

-- Preguntar si se quiere filtrar por método
local function ask_filter()
	pickers
		.new({}, {
			prompt_title = "¿Filtrar por método HTTP?",
			finder = finders.new_table({
				results = filter_options,
				entry_maker = function(option)
					return {
						value = option,
						display = option,
						ordinal = option,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry().value
					actions.close(prompt_bufnr)

					if selection == "Sí" then
						-- Si elige "Sí", preguntar por el método
						pickers
							.new({}, {
								prompt_title = "Selecciona el Método HTTP",
								finder = finders.new_table({
									results = http_methods,
									entry_maker = function(method)
										return {
											value = method,
											display = method,
											ordinal = method,
										}
									end,
								}),
								sorter = conf.generic_sorter({}),
								attach_mappings = function(method_bufnr, map)
									actions.select_default:replace(function()
										local method = action_state.get_selected_entry().value
										actions.close(method_bufnr)
										search_endpoints(method) -- Buscar con filtro
									end)
									return true
								end,
							})
							:find()
					else
						search_endpoints(nil) -- Buscar sin filtro
					end
				end)
				return true
			end,
		})
		:find()
end

return {
	search_endpoints = ask_filter,
}
