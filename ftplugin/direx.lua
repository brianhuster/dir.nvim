local api = vim.api
local buf = vim.api.nvim_get_current_buf()
---@module 'direx'
local dir = setmetatable({}, { __index = function(_, k) return require('direx')[k] end })
local bufcmd = api.nvim_buf_create_user_command
local bufmap = require('direx.utils').bufmap

vim.bo.bufhidden = 'delete'
vim.bo.buftype = 'nowrite'
vim.bo.swapfile = false

local function get_lines_from_cmd_range(args)
	return args.range > 0 and api.nvim_buf_get_lines(0, args.line1 - 1, args.line2, false) or nil
end

require('direx.utils').add_icons()

vim.cmd.sort [[/^.*[/]/]]
vim.fn.search([[\V\C]] .. vim.fn.escape(vim.w.prev_bufname, '\\'), 'cw')

bufmap('n', '<CR>', function() vim.cmd.edit(api.nvim_get_current_line()) end,
	{ desc = 'Open file or directory under cursor' })
bufmap('n', 'grn', function() dir.rename() end, { desc = 'Rename path under cursor' })
bufmap('n', 'g?', '<cmd>help direx-mappings<CR>')

bufcmd(buf, 'Cut', function(args)
	local lines = get_lines_from_cmd_range(args) or { api.nvim_get_current_line() }
	dir.cut(lines)
end, {
	range = true,
	desc = 'Cut selected files and directories for later pasting'
})

bufcmd(buf, 'Copy', function(args)
	local lines = args.range > 0 and api.nvim_buf_get_lines(0, args.line1 - 1, args.line2, false) or
		{ api.nvim_get_current_line() }
	dir.copy(lines)
end, {
	range = true,
	desc = 'Copy selected files and directories for later pasting'
})

bufcmd(buf, 'Paste', function() dir.paste() end, { desc = 'Execute shell command with optional range and arguments' })

bufcmd(buf, 'Remove', function(args)
	local lines = get_lines_from_cmd_range(args) or { api.nvim_get_current_line() }
	dir.remove(lines, { confirm = args.bang == false })
end, { desc = 'Remove selected files and directories', range = true, bang = true })

bufcmd(buf, 'Trash', function(args)
	local lines = get_lines_from_cmd_range(args) or { api.nvim_get_current_line() }
	dir.trash(lines, { confirm = args.bang == false })
end, { range = true, bang = true, desc = 'Trash selected files and directories' })

bufcmd(buf, 'LFind', function(cmd)
	require 'direx'.find(cmd.args, { wintype = 'location', from_dir = api.nvim_buf_get_name(0) })
end, { nargs = '+', desc = 'Find files/folders <arg> in directory and its subdirectories, then open location window' })

bufcmd(buf, 'LGrep', function(cmd)
	local pattern = require 'direx.utils'.get_grep_pattern(cmd)
	require 'direx'.grep(pattern, { wintype = 'location', from_dir = api.nvim_buf_get_name(0) })
end, { nargs = '+', desc = 'Grep <arg> in directory and its subdirectories, then open location window' })

local augroup = vim.api.nvim_create_augroup('DirexBuf', { clear = true })
vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedP', 'InsertLeave' }, {
	buffer = buf,
	group = augroup,
	callback = function()
		require('direx.utils').add_icons()
	end
})

vim.b.undo_ftplugin = table.concat({
	"setl bufhidden< buftype< swapfile<",
	"silent! nunmap <CR> grn g?",
	"silent! delcommand -buffer Cut Copy Paste Trash Remove LFind LGrep",
	"augroup DirexBuf | au! | augroup END",
}, "\n")
