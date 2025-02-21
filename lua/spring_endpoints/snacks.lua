local snacks = require("snacks.picker")
local parser = require("spring_endpoints.parser")

local http_methods = { "GET", "POST", "PUT", "DELETE", "PATCH" }

-- Función para abrir el archivo en la línea del endpoint
local function open_file(entry)
	vim.cmd("edit " .. entry.file)
	vim.fn.search(entry.path, "w")
end

-- Seleccionar método HTTP antes de buscar rutas
local function select_http_method(callback)
	snacks.show({
		prompt = "Selecciona el Método HTTP",
		items = http_methods,
		format = "[${text}]", -- Mostrar métodos en lista
		actions = {
			["confirm"] = function(selected)
				if selected then
					callback(selected.text) -- Llamar al siguiente paso con el método elegido
				end
			end,
		},
	})
end

-- Buscar endpoints filtrados por el método HTTP seleccionado
local function search_endpoints(method)
	local endpoints = parser.find_endpoints(vim.fn.getcwd())

	-- Filtrar solo los endpoints con el método seleccionado
	local filtered_endpoints = {}
	for _, ep in ipairs(endpoints) do
		if ep.method == method then
			table.insert(filtered_endpoints, ep)
		end
	end

	if #filtered_endpoints == 0 then
		print("No hay endpoints con el método " .. method)
		return
	end

	-- Mostrar los endpoints con Snacks Picker
	snacks.pick(nil, {
		prompt = "Endpoints " .. method,
		items = filtered_endpoints,
		format = function(entry)
			return string.format("[%s] %s", entry.method, entry.path)
		end,
		actions = {
			["confirm"] = function(picker, selected)
				if selected then
					open_file(selected)
				end
			end,
		},
	})
end

-- Función principal para iniciar la búsqueda con Snacks Picker
local function search()
	select_http_method(search_endpoints)
end

return {
	search_endpoints = search,
}
