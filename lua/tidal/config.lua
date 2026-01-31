local M = {}

M.defaults = {
	ghci = "ghci",
	boot = nil,
	flash_duration = 150,
	sc_enable = false,
	sclang = "sclang",
	sc_boot = nil,
	no_mappings = false,
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

local function file_exists(path)
	local stat = vim.loop.fs_stat(path)
	return stat and stat.type == "file"
end

local function search_upward(start_dir, filenames)
	local dir = start_dir
	while dir and dir ~= "/" do
		for _, name in ipairs(filenames) do
			local path = dir .. "/" .. name
			if file_exists(path) then
				return path
			end
		end
		dir = vim.fn.fnamemodify(dir, ":h")
	end
	return nil
end

function M.find_boot_file()
	if M.options.boot then
		return M.options.boot
	end

	local env_boot = vim.env.TIDAL_BOOT_PATH
	if env_boot and file_exists(env_boot) then
		return env_boot
	end

	local cwd = vim.fn.getcwd()
	local found = search_upward(cwd, { "BootTidal.hs", "Tidal.ghci", "boot.tidal" })
	if found then
		return found
	end

	local plugin_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h")
	local default_boot = plugin_dir .. "/Tidal.ghci"
	if file_exists(default_boot) then
		return default_boot
	end

	return nil
end

function M.find_sc_boot()
	if M.options.sc_boot then
		return M.options.sc_boot
	end

	local cwd = vim.fn.getcwd()
	local found = search_upward(cwd, { "boot.sc", "boot.scd" })
	if found then
		return found
	end

	local plugin_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h")
	local default_boot = plugin_dir .. "/boot.sc"
	if file_exists(default_boot) then
		return default_boot
	end

	return nil
end

return M
