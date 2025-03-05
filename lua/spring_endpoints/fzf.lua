local fzf_lua = require("fzf-lua")
local parser = require("spring_endpoints.parser")

local function open_file(entry)
	vim.cmd("edit " .. entry.file)
	vim.fn.search(entry.path, "w")
end

local function search_endpoints()
	local endpoints = parser.find_endpoints(vim.fn.getcwd())

	-- Filtrar los endpoints que NO contengan "[REQUEST]"
	local filtered_endpoints = {}
	for _, ep in ipairs(endpoints) do
		if not ep.path:match("^REQUEST") then
			table.insert(filtered_endpoints, ep)
		end
	end

	-- Configurar fzf-lua para mostrar los endpoints
	fzf_lua.fzf_exec(function(cb)
		for _, ep in ipairs(filtered_endpoints) do
			cb(string.format("[%s] %s", ep.method, ep.path))
		end
		cb(nil) -- Finalizar la lista
	end, {
		actions = {
			["default"] = function(selected)
				local selected_entry = selected[1]
				if selected_entry then
					local method, path = selected_entry:match("%[([^%]]+)%]%s+(.+)")
					if method and path then
						for _, ep in ipairs(filtered_endpoints) do
							if ep.method == method and ep.path == path then
								open_file(ep)
								break
							end
						end
					end
				end
			end,
		},
		prompt = "Spring Boot Endpoints> ",
	})
end

return {
	search_endpoints = search_endpoints,
}
