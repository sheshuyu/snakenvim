-- snakenvim — 浮动终端
--
-- 不装插件:浮动窗口 + 一个常驻的终端缓冲区,几十行就够,
-- 而且行为完全可控(插件多数是包一层 GUI,反而不好调)。
--
-- 用法:<C-\> 开关(为什么不是 <Space>tt,见 config/keymaps.lua)。
-- 收起浮窗有三条路:
--   * 终端里直接按 <C-q>            —— 一步,最快
--   * <Esc><Esc> 回普通模式再按 q    —— 和 help / quickfix 窗口的习惯一致
--   * 再按一次 <C-\>
-- 收起来不会杀掉进程,下次打开还是原来的会话。

local M = {}

local state = { win = nil, dir = nil }

local function is_open()
  return state.win ~= nil and vim.api.nvim_win_is_valid(state.win)
end

--- 当前文件所在目录;没名字的缓冲区(比如刚启动)退回 nvim 自己的 cwd。
-- 终端就开在这里,这样打开 .c 文件后按 <C-\> 就能直接
-- gcc xxx.c -o xxx && ./xxx,不用先 cd。
local function target_dir()
  local name = vim.api.nvim_buf_get_name(0)
  if name ~= '' then
    local dir = vim.fn.fnamemodify(name, ':p:h')
    if dir ~= '' and vim.fn.isdirectory(dir) == 1 then
      return dir
    end
  end
  return vim.uv.cwd()
end

local function has_terminal()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == 'snakenvim_term' then
      return buf
    end
  end
  return nil
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

--- 起一个新终端(会先把旧的关掉),目录用当前文件所在的
local function spawn()
  local old = has_terminal()
  if old then
    pcall(vim.api.nvim_buf_delete, old, { force = true })
  end

  state.dir = target_dir()

  -- 先在当前窗口占一个空缓冲区,再用 termopen 指定 cwd 启动 shell,
  -- 最后把这个窗口转成浮窗。直接 :terminal 的话 cwd 是 nvim 自己的目录,
  -- 编译当前文件还得先手动 cd。
  vim.cmd('botright new')
  local buf = vim.api.nvim_get_current_buf()
  state.win = vim.api.nvim_get_current_win()

  vim.fn.termopen(vim.o.shell, { cwd = state.dir })
  vim.bo[buf].filetype = 'snakenvim_term'
  apply_float(state.win)
  vim.cmd('startinsert')
end

function M.toggle()
  if is_open() then
    -- 用 win_hide 而不是 win_close:保留缓冲区和里面的进程,
    -- 下次打开还是同一个终端会话(win_close 会把进程一起杀掉)
    vim.api.nvim_win_hide(state.win)
    state.win = nil
    return
  end

  local buf = has_terminal()
  if buf then
    -- ⚠️ 必须在打开浮窗【之前】算当前文件在哪,顺序不能挪。
    --
    -- 下面 nvim_open_win 的第二个参数是 true,意思是「进入这个窗口」——
    -- 当前缓冲区随即变成终端缓冲区。那时再调 target_dir(),读到的名字是
    -- term://...,fnamemodify 出来是 "term://…/bin" 这种不是目录的东西,
    -- isdirectory 判定失败,于是退回 vim.uv.cwd()。
    -- 结果就是提示里的「当前文件在 X」显示成 nvim 的工作目录,而不是你的
    -- 文件真正在哪 —— 而且只要 cwd 和终端目录不同就会误报。
    local want = target_dir()

    -- 复用已有的终端会话,不重新起(里面跑的东西还在)
    state.win = vim.api.nvim_open_win(buf, true, {
      relative = 'editor',
      width = 1,
      height = 1,
      row = 0,
      col = 0,
    })
    apply_float(state.win)
    vim.cmd('startinsert')

    -- 复用时目录不会自动跟着当前文件走 —— 故意的:往里发 cd 命令有风险,
    -- 如果 shell 里正有个程序在等输入,那串 cd 会被当成它的输入吃掉。
    -- 所以只在目录不一致时提示一句,想换目录用 <Space>tT 重开。
    if state.dir and want ~= state.dir then
      -- 写成一行纯粹是为了清爽。补充说明:以前这里还怕多行会触发
      -- "Press ENTER or type command to continue"(命令行区域放不下多行),
      -- 现在通知已经走 mini.notify 的浮窗(见 plugins/editor.lua),那个限制没有了。
      vim.notify(
        ("snakenvim:终端停在 %s,当前文件在 %s —— 按 <Space>tT 重开"):format(
          vim.fn.fnamemodify(state.dir, ':t'),
          vim.fn.fnamemodify(want, ':t')
        ),
        vim.log.levels.INFO
      )
    end
    return
  end

  spawn()
end

--- 重开一个终端,目录取当前文件所在的(会话里的东西会没,但目录跟得上)
function M.restart()
  if is_open() then
    vim.api.nvim_win_hide(state.win)
    state.win = nil
  end
  spawn()
end

--- 终端里按 <Esc><Esc> 回普通模式。只在我们的终端缓冲区里生效,
--- 不影响普通 buffer 的映射。
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('snakenvim_term', { clear = true }),
  pattern = 'snakenvim_term',
  callback = function(args)
    vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { buf = args.buf, desc = '终端:回普通模式' })

    -- 终端模式下一步收起,不用先 <Esc><Esc> 再按 q。
    --
    -- 为什么选 <C-q>:它原本是终端的 XON 流控(<C-s> 暂停输出、<C-q> 恢复),
    -- 日常几乎用不到,nvim 先截走就等于接管了它。而 <C-a>/<C-e>/<C-r>/<C-w>
    -- 这些是 readline 的常用键,抢了会难受;
    -- <C-c>/<C-d>/<C-z> 更不能碰(中断 / EOF / 挂起)。
    --
    -- ⚠️ 别顺手改成 <Space>tt:空格在 shell 里是最普通的字符。一旦它成了映射
    -- 前缀,终端里每打一个空格都要等 timeoutlen(400ms)才会送进 shell ——
    -- 等于把终端废掉。这和 plugins/explorer.lua 里不把 <Space>e 绑成 yazi
    -- 切换键是同一个道理。
    vim.keymap.set('t', '<C-q>', function()
      M.toggle()
    end, { buf = args.buf, desc = '终端:收起浮窗' })

    -- 普通模式下按 q 收起浮窗(和 help/qf 的行为一致)
    vim.keymap.set('n', 'q', function()
      M.toggle()
    end, { buf = args.buf, desc = '收起终端' })
  end,
})

return M
