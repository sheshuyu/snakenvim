-- snake's neovim — 启动界面
--
-- 用 alpha-nvim:它只提供 text / padding / button / group 四个布局原语,
-- 正好对应「一段 ASCII header + 几个入口」的需求,不夹带文件浏览器之类的
-- 重复功能(找文件我们已经有 telescope 了)。
--
-- 两个容易踩的坑(都踩过了):
--   1. 没有 type = 'header' 这种东西 —— header 就是 type = 'text'
--      ('header' 是 dashboard-nvim 的写法,混用会直接报
--       "attempt to call a nil value")
--   2. 按钮的 opts.shortcut 会被 alpha 自动拼在 val 前面,
--      val 里不要再写一遍快捷键字母,否则会渲染成 "n n 新建文件"

-- ── ASCII 字体 ──────────────────────────────────────────────────────────
-- 用字形表而不是直接写多行字符串:每个字母只定义一次,五行天然对齐。
-- 想换字样(比如改成 SNAKE)只需改下面 render() 的入参。
--
-- 字符用的是 █ 全角块。这条路子是给 iPad + mosh 场景选的:
-- █ 和空格在任何等宽字体里都有,不像 Nerd Font 私有码点会变豆腐块。
local FONT = {
  S = { '█████', '█    ', '█████', '    █', '█████' },
  N = { '█   █', '██  █', '█ █ █', '█  ██', '█   █' },
  A = { ' ███ ', '█   █', '█████', '█   █', '█   █' },
  K = { '█   █', '█  █ ', '███  ', '█  █ ', '█   █' },
  E = { '█████', '█    ', '████ ', '█    ', '█████' },
  V = { '█   █', '█   █', '█   █', ' █ █ ', '  █  ' },
  I = { '███', ' █ ', ' █ ', ' █ ', '███' },
  M = { '█   █', '██ ██', '█ █ █', '█   █', '█   █' },
}

--- 显示宽度(CJK 占 2 列,不能用 # 数长度)
local function width(s)
  return vim.fn.strdisplaywidth(s)
end

--- 取一个字母的 5 行字形,并把每行补齐到该字母最宽的那一行。
-- 字形表是手写的,某行多一个少一个空格很容易发生 —— 补一次宽度,
-- 整幅画就不会因此错位(第一版 E 的中间行多一个空格,就让第 3 行比别人宽 1 列)。
local function glyph(ch)
  local g = FONT[ch]
  if not g then
    return nil
  end
  local w = 0
  for _, row in ipairs(g) do
    w = math.max(w, width(row))
  end
  local out = {}
  for i, row in ipairs(g) do
    out[i] = row .. string.rep(' ', w - width(row))
  end
  return out
end

--- 把一段文字渲染成 5 行 ASCII 字符画,字母之间空一格
local function render(word, spacing)
  spacing = spacing or ' '
  local rows = { '', '', '', '', '' }
  local first = true
  for i = 1, #word do
    local g = glyph(word:sub(i, i):upper())
    if g then
      for r = 1, 5 do
        rows[r] = rows[r] .. (first and '' or spacing) .. g[r]
      end
      first = false
    end
  end
  return rows
end

local HEADER = render('SNAKENVIM')
local HEADER_WIDTH = width(HEADER[1])
local HEADER_MAX = 60 -- 超过这个宽度在窄窗口里会被折行

-- ── 按钮 ────────────────────────────────────────────────────────────────
-- 每项是 { 标签, 快捷键, 动作 }。标签**不要**带快捷键字母。
local ENTRIES = {
  {
    ' 新建文件',
    'n',
    function()
      vim.ui.input({ prompt = '新文件路径: ', completion = 'file' }, function(input)
        if input and input ~= '' then
          vim.cmd.edit(vim.fn.fnameescape(input))
        end
      end)
    end,
  },
  {
    ' 查找文件',
    'f',
    function()
      require('telescope.builtin').find_files()
    end,
  },
  {
    ' 最近打开的文件',
    'r',
    function()
      require('telescope.builtin').oldfiles()
    end,
  },
  {
    -- 用 :Oil 而不是 require('oil'):oil 是懒加载的,直接 require 会因为
    -- 模块还不在 runtimepath 上而失败。:Oil 命令由 lazy 在加载插件时创建,
    -- 调用它会自动触发加载。
    ' 打开配置目录',
    'c',
    function()
      vim.cmd('Oil ' .. vim.fn.fnameescape(vim.fn.stdpath('config')))
    end,
  },
  {
    ' 退出',
    'q',
    function()
      vim.cmd.quit()
    end,
  },
}

-- 让所有按钮等宽,这样文字会左对齐成一列,而不是每行各自居中显得参差
local BUTTON_WIDTH = 0
for _, e in ipairs(ENTRIES) do
  BUTTON_WIDTH = math.max(BUTTON_WIDTH, width(e[1]) + #e[2])
end
BUTTON_WIDTH = BUTTON_WIDTH + 4

local buttons = {
  type = 'group',
  val = vim.tbl_map(function(e)
    return {
      type = 'button',
      val = e[1],
      on_press = e[3],
      opts = {
        shortcut = e[2],
        -- shortcut 只负责「显示」,不会真的绑按键 —— 必须另外给 keymap。
        -- 不写这个的话,只有把光标移到按钮行上按回车才能触发,
        -- 直接按 n / f / r 是没反应的。
        -- alpha 会自动把这条 keymap 改成缓冲区局部,不会泄漏到别的缓冲区。
        keymap = { 'n', e[2], e[3], { noremap = true, silent = true, nowait = true } },
        position = 'center',
        cursor = 1,
        width = BUTTON_WIDTH,
        hl = 'SnakeDashboardButton',
        hl_shortcut = 'SnakeDashboardShortcut',
      },
    }
  end, ENTRIES),
  opts = { spacing = 1 },
}

local layout = {
  { type = 'padding', val = 2 },
  {
    -- 注意是 text 不是 header
    type = 'text',
    val = HEADER,
    opts = { position = 'center', hl = 'SnakeDashboardHeader' },
  },
  { type = 'padding', val = 2 },
  buttons,
  { type = 'padding', val = 1 },
  {
    type = 'text',
    val = { "snake's neovim", '按 <Space> 查看所有键位' },
    opts = { position = 'center', hl = 'SnakeDashboardFooter' },
  },
}

return {
  {
    'goolord/alpha-nvim',
    -- 只在「不带任何文件参数启动」时加载。带参数启动(比如 nvim foo.c)时
    -- 整个插件都不会加载,不浪费启动时间。
    -- 注意 alpha 自己也会判断:带了 -c / + 等参数时它会主动跳过,
    -- 所以自动化的 headless 测试里看不到界面,这是正常的。
    cond = function()
      return vim.fn.argc() == 0
    end,
    lazy = false,
    config = function()
      if HEADER_WIDTH > HEADER_MAX then
        vim.schedule(function()
          vim.notify(
            ("snake's neovim:启动界面 header 宽 %d 列,超过 %d,可能在窄窗口里被折行"):format(
              HEADER_WIDTH,
              HEADER_MAX
            ),
            vim.log.levels.WARN
          )
        end)
      end

      -- 高亮一律用 link 跟随配色,换主题时会自动跟着变,不需要重新设置
      vim.api.nvim_set_hl(0, 'SnakeDashboardHeader', { link = 'Title' })
      vim.api.nvim_set_hl(0, 'SnakeDashboardButton', { link = 'Normal' })
      vim.api.nvim_set_hl(0, 'SnakeDashboardShortcut', { link = 'Special' })
      vim.api.nvim_set_hl(0, 'SnakeDashboardFooter', { link = 'Comment' })

      -- 隐藏 "type :help<Enter>..." 那行启动提示
      vim.opt.shortmess:append('I')

      require('alpha').setup({
        layout = layout,
        opts = { margin = 5 },
      })

      -- alpha 自己已经把行号、相对行号、符号列、cursorline 都关掉了,
      -- 但 laststatus 是**全局**选项,它管不了。我们在 options.lua 里设了
      -- 全局状态栏(laststatus=3),不处理的话启动界面底部会挂一条
      -- 显示 "alpha" 空缓冲区的状态栏,很难看。
      local aug = vim.api.nvim_create_augroup('snake_dashboard_chrome', { clear = true })

      vim.api.nvim_create_autocmd('FileType', {
        group = aug,
        pattern = 'alpha',
        callback = function()
          vim.o.laststatus = 0
        end,
      })

      vim.api.nvim_create_autocmd('BufEnter', {
        group = aug,
        callback = function()
          if vim.bo.filetype ~= 'alpha' then
            vim.o.laststatus = 3
          end
        end,
      })
    end,
  },
}
