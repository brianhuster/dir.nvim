local api = vim.api
local dir = setmetatable({}, { __index = function(_, k) return require('direx')[k] end })
local bufmap = require('direx.utils').bufmap
local bufcmd = api.nvim_buf_create_user_command

vim.wo[0][0].conceallevel = 3
vim.wo[0][0].concealcursor = 'nvc'
vim.wo[0][0].wrap = false

local function feedkeys(key)
	api.nvim_feedkeys(vim.keycode(key), 'n', true)
end

require('direx.utils').add_icons()

local function get_lines_from_cmd_range(args)
	return args.range > 0 and api.nvim_buf_get_lines(0, args.line1 - 1, args.line2, false) or nil
end

bufmap('n', 'K', function() dir.hover() end, { desc = 'View file or folder info' })
bufmap('n', '<Plug>(direx-preview)', function() dir.preview(api.nvim_get_current_line()) end,
	{ desc = 'Preview file or directory' })
if vim.fn.hasmapto('<Plug>(direx-preview)', 'n') == 0 then
	bufmap('n', 'P', '<Plug>(direx-preview)', { desc = 'Preview file or directory' })
end
bufmap('n', '!', function()
	feedkeys(':<C-U><Space>')
	local path = vim.fn.shellescape(api.nvim_get_current_line(), true)
	feedkeys(path .. '<C-b>!')
end, {})

bufmap('x', '!', function() feedkeys(':Shdo  {}<Left><Left><Left>') end)

bufcmd(0, 'Shdo', function(args)
	local lines = get_lines_from_cmd_range(args)
	if not lines then return end
	require 'direx'.shdo(args.args, vim.fs.abspath(api.nvim_buf_get_name(0)), lines)
end, {
	range = true,
	nargs = '+',
	complete = 'shellcmd',
	desc = 'Execute shell command with optional range and arguments'
})

bufcmd(0, 'DirexFind', function(cmd)
	require 'direx'.find(cmd.args, { from_dir = api.nvim_buf_get_name(0) })
end, { nargs = '+', desc = 'Find files/folders <arg> in directory and its subdirectories, then open location window' })

bufcmd(0, 'DirexGrep', function(cmd)
	local pattern = require 'direx.utils'.get_grep_pattern(cmd)
	require 'direx'.grep(pattern, { from_dir = api.nvim_buf_get_name(0) })
end, { nargs = '+', desc = 'Grep <arg> in directory and its subdirectories, then open location window' })

bufcmd(0, 'DirexLFind', function(cmd)
	require 'direx'.find(cmd.args, { wintype = 'location', from_dir = api.nvim_buf_get_name(0) })
end, { nargs = '+', desc = 'Find files/folders <arg> in directory and its subdirectories, then open location window' })

bufcmd(0, 'DirexLGrep', function(cmd)
	local pattern = require 'direx.utils'.get_grep_pattern(cmd)
	require 'direx'.grep(pattern, { wintype = 'location', from_dir = api.nvim_buf_get_name(0) })
end, { nargs = '+', desc = 'Grep <arg> in directory and its subdirectories, then open location window' })

vim.b.undo_ftplugin = table.concat({
	vim.b.undo_ftplugin or '',
	"setl conceallevel< concealcursor< wrap<",
	"silent! nunmap <CR> K P !",
	"silent! delcommand -buffer Shdo DirexFind DirexGrep DirexLFind DirexLGrep",
	"silent! xunmap !"
}, '\n')
