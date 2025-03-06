local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local parser = require("spring_endpoints.parser")

local function open_file(entry)
	-- Abrir el archivo
	vim.cmd("edit " .. entry.file)
	print("📂 Archivo abierto: " .. entry.file)

	-- Extraer la posible ruta base y el endpoint final
	local base_path, method_path = entry.path:match("^(.-)/([^/]+)$")
	if not base_path or base_path == "" then
		base_path = ""
		method_path = entry.path
	end
	print("📌 Ruta base: " .. base_path)
	print("📌 Ruta del método: " .. method_path)

	-- Capitalizar correctamente el método (por ejemplo, "get" -> "Get")
	local capitalized_method = entry.method:sub(1, 1):upper() .. entry.method:sub(2):lower()
	print("🔍 Método capitalizado: " .. capitalized_method)

	-- Función para buscar un patrón en el archivo
	local function search_pattern(pattern)
		print("🔎 Buscando patrón: " .. pattern)
		vim.fn.cursor(1, 1) -- Empezar la búsqueda desde el inicio del archivo
		local found_line = vim.fn.search(pattern, "w")
		if found_line ~= 0 then
			print("✅ Patrón encontrado en la línea: " .. found_line)
		else
			print("❌ Patrón no encontrado.")
		end
		return found_line
	end

	-- 1️⃣ Buscar la anotación @RequestMapping("api/nivel")
	local class_pattern = '@RequestMapping("' .. base_path .. '")'
	print("🧐 Buscando anotación de la clase con patrón: " .. class_pattern)
	local found_class = search_pattern(class_pattern)

	-- 2️⃣ Si se encuentra la anotación de la clase, buscar la anotación del método dentro de esa clase
	if found_class ~= 0 then
		print("✅ Anotación de clase encontrada en la línea: " .. found_class)

		-- Buscar la anotación del método dentro de la clase
		local method_pattern = "@" .. capitalized_method .. 'Mapping("/' .. method_path .. '")'
		print("🔍 Buscando anotación del método con patrón: " .. method_pattern)
		local found_method = search_pattern(method_pattern)

		if found_method ~= 0 then
			print("✅ Anotación del método encontrada en la línea: " .. found_method)
			vim.fn.cursor(vim.fn.line("."), 1) -- Mover cursor al inicio de la línea
			vim.api.nvim_command("normal! zz") -- Centrar la ventana en el cursor
			return
		else
			print("❌ No se encontró la anotación del método dentro de la clase.")
		end
	else
		print("❌ No se encontró la anotación de la clase.")
	end

	-- 3️⃣ Si no se encuentra la anotación de la clase, buscar la ruta completa @PostMapping("api/nivel/datosReporteNiveles")
	local full_method_pattern = "@" .. capitalized_method .. 'Mapping("' .. entry.path .. '")'
	print("🔎 Buscando anotación del método con ruta completa: " .. full_method_pattern)
	local found_full_method = search_pattern(full_method_pattern)

	if found_full_method ~= 0 then
		print("✅ Anotación del método encontrada en la línea: " .. found_full_method)
		vim.fn.cursor(vim.fn.line("."), 1) -- Mover cursor al inicio de la línea
		vim.api.nvim_command("normal! zz") -- Centrar la ventana en el cursor
		return
	else
		print("❌ No se encontró la anotación del método con la ruta completa.")
	end

	-- 4️⃣ Si no se encuentra nada, mostrar un mensaje de advertencia
	print("⚠️ No se pudo encontrar la anotación del endpoint.")
end

local function search_endpoints()
	local endpoints = parser.find_endpoints(vim.fn.getcwd())

	local seen_paths = {} -- Para evitar duplicados
	-- Filtrar los endpoints que NO contengan "[REQUEST]" y que NO tengan entry.method == "REQUEST"
	local filtered_endpoints = {}
	for _, ep in ipairs(endpoints) do
		if not ep.path:match("^REQUEST") and ep.method ~= "REQUEST" and not seen_paths[ep.path] then
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
