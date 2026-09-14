-- snake's neovim — 浮动终端
--
-- 不装插件:浮动窗口 + 一个常驻的终端缓冲区,几十行就够,
-- 而且行为完全可控(插件多数是包一层 GUI,反而不好调)。
--
-- 用法:<Space>tt 开关。终端里按 <Esc><Esc>(或 <C-\><C-n>)回普通模式,
-- 再按一次 <Space>tt 收起。收起来不会杀掉进程,下次打开还是原来的会话。

local M = {}

local state = { win = nil }

local function is_open()
  return state.win ~= nil and vim.api.nvim_win_is_valid(state.win)
end

--- 尺寸取窗口的 80% x 60%,但至少留 4 行/列的边
local function geometry()
  local cols, rows = vim.o.columns, vim.o.lines
  local w = math.max(20, math.min(math.floor(cols * 0.8), cols - 4))
  local h = math.max(6, math.min(math.floor(rows * 0.6), rows - 4))
  return w, h, cols, rows
end

local function apply_float(win)
  local w, h, cols, rows = geometry()
  vim.api.nvim_win_set_config(win, {
    relative = 'editor',
    width = w,
    height = h,
    row = math.max(0, math.floor((rows - h) / 2) - 1),
    col = math.floor((cols - w) / 2),
    style = 'minimal',
    border = 'rounded',
    title = ' 终端 ',
    title_pos = 'center',
  })
end

function M.toggle()
  if is_open() then
    -- 用 win_hide 而不是 win_close:保留缓冲区和里面的进程,
    -- 下次打开还是同一个终端会话(win_close 会把进程一起杀掉)
    vim.api.nvim_win_hide(state.win)
    state.win = nil
    return
  end

  -- 已经有活着的终端缓冲区就直接复用
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == 'snake_term' then
      state.win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = 1,
        height = 1,
        row = 0,
        col = 0,
      })
      apply_float(state.win)
      vim.cmd('startinsert')
      return
    end
  end

  -- 第一次:先在当前窗口开终端,再把这个窗口转成浮窗
  vim.cmd('botright new')
  vim.cmd('terminal')
  local buf = vim.api.nvim_get_current_buf()
  state.win = vim.api.nvim_get_current_win()

  vim.bo[buf].filetype = 'snake_term'
  apply_float(state.win)
  vim.cmd('startinsert')
end

--- 终端里按 <Esc><Esc> 回普通模式。只在我们的终端缓冲区里生效,
--- 不影响普通 buffer 的映射。
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('snake_term', { clear = true }),
  pattern = 'snake_term',
  callback = function(args)
    vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { buf = args.buf, desc = '终端:回普通模式' })
    -- 普通模式下按 q 收起浮窗(和 help/qf 的行为一致)
    vim.keymap.set('n', 'q', function()
      M.toggle()
    end, { buf = args.buf, desc = '收起终端' })
  end,
})

return M
