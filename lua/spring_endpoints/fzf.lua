local fzf = require("fzf-lua")
local parser = require("spring_endpoints.parser")

-- Intentar usar 'bat' si está disponible, sino usar 'cat'
local preview_cmd
if vim.fn.executable("bat") == 1 then
	preview_cmd = "bat --style=plain --color=always --highlight-line={2} {1}"
else
	preview_cmd = "awk 'NR>={2}-5 && NR<={2}+5' {1} | sed -e '{2}s/^/\033[1;31m/;{2}s/$/\033[0m/'"
end

local function open_file(entry)
	if entry and entry.file then
		vim.cmd("edit " .. entry.file)
		vim.fn.search(entry.path, "w")
	else
		print("Error: No se pudo abrir el archivo.")
	end
end

local function search_endpoints()
	local endpoints = parser.find_endpoints(vim.fn.getcwd())

	if #endpoints == 0 then
		print("No endpoints found.")
		return
	end

	local entries = {}
	local endpoint_map = {}

	for _, ep in ipairs(endpoints) do
		local display_text = string.format("[%s] %s | %s", ep.method, ep.path, ep.file)
		table.insert(entries, display_text)
		endpoint_map[display_text] = ep
	end

	fzf.fzf_exec(entries, {
		prompt = "Spring Endpoints> ",
		preview = function(entry)
			local endpoint = endpoint_map[entry]
			if not endpoint then
				return nil
			end

			-- Buscar la línea donde aparece el endpoint en el archivo
			local grep_cmd = string.format("grep -n '%s' %s | cut -d: -f1", endpoint.path, endpoint.file)
			local handle = io.popen(grep_cmd)
			local line = handle:read("*l")
			handle:close()

			if line then
				return string.format(preview_cmd, endpoint.file, tonumber(line))
			else
				return string.format("cat %s", endpoint.file) -- Si no encuentra la línea, mostrar todo el archivo
			end
		end,
		actions = {
			["default"] = function(selected)
				local selected_text = selected[1]
				local endpoint = endpoint_map[selected_text]
				if endpoint then
					open_file(endpoint)
				end
			end,
		},
	})
end

return {
	search_endpoints = search_endpoints,
}
