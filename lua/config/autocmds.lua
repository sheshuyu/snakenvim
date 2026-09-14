-- snakenvim — 自动命令

local group = vim.api.nvim_create_augroup('snakenvim_autocmds', { clear = true })

-- ── 重新打开文件时回到上次的光标位置 ────────────────────────────────────
vim.api.nvim_create_autocmd('BufReadPost', {
  group = group,
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(args.buf)
    -- 第 0 行是无效位置;行号超出文件长度说明文件被改短过,也不跳
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- ── 复制时短暂高亮,确认到底复制了什么 ──────────────────────────────────
vim.api.nvim_create_autocmd('TextYankPost', {
  group = group,
  callback = function()
    vim.hl.on_yank({ higroup = 'IncSearch', timeout = 150 })
  end,
})

-- ── 终端窗口大小变化后,让分屏重新均分 ──────────────────────────────────
vim.api.nvim_create_autocmd('VimResized', {
  group = group,
  callback = function()
    vim.cmd('tabdo wincmd =')
  end,
})

-- ── 这些只读面板用 q 关闭 ───────────────────────────────────────────────
vim.api.nvim_create_autocmd('FileType', {
  group = group,
  pattern = { 'help', 'qf', 'man', 'checkhealth', 'lspinfo', 'query' },
  callback = function(args)
    vim.keymap.set('n', 'q', '<cmd>close<CR>', { buf = args.buf, desc = '关闭' })
  end,
})

-- ── 文件被外部改动时自动重新载入 ────────────────────────────────────────
-- 必须用 Lua 回调而不是 command 字符串:后者会被当作单条 ex 命令解析,
-- 里面出现 | 会直接报 E488。
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold' }, {
  group = group,
  callback = function()
    if vim.fn.mode() == 'n' then
      vim.cmd('checktime')
    end
  end,
})

-- ── :Snakenvim 状态速查 ─────────────────────────────────────────────────
-- :Snake 留作短别名,打字方便
local function show_status()
  local lines = require('snakenvim.health').summary()
  vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO, { title = 'snakenvim' })
end

vim.api.nvim_create_user_command('Snakenvim', show_status, { desc = '显示 snakenvim 当前状态' })
vim.api.nvim_create_user_command('Snake', show_status, { desc = '同 :Snakenvim(短别名)' })
