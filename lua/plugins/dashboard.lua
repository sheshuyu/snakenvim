-- snake's neovim — 启动界面
--
-- 用 alpha-nvim:它只提供 text / padding / button / group 四个布局原语,
-- 正好对应「一段 ASCII header + 几个入口」的需求,不夹带文件浏览器之类的
-- 重复功能(找文件我们已经有 telescope 了)。
--
-- 三个容易踩的坑(都踩过了):
--   1. 没有 type = 'header' 这种东西 —— header 就是 type = 'text'
--      ('header' 是 dashboard-nvim 的写法,混用会直接报
--       "attempt to call a nil value")
--   2. 按钮的 opts.shortcut 只负责显示,不会绑按键,必须另外给 opts.keymap
--   3. 按钮的 val 里不要再写一遍快捷键字母,alpha 会自动把 shortcut 拼在前面
--
-- 布局是**每次按窗口大小现算的**,不是写死的:alpha 原生只会从上往下排,
-- 不垂直居中,所以窗口一大内容就全挤在顶部、下面空一大片。这里自己算
-- 顶部留白把内容摆到垂直中间,宽屏时还会把字形整数放大一档。

-- ── 可调项 ──────────────────────────────────────────────────────────────

-- 是否随窗口自适应(垂直居中 + 宽屏放大字形)。false 则固定 1 倍、顶部留 2 行
local ADAPTIVE = true

-- 强制字形倍率:1 = 51 列、2 = 102 列。nil = 按窗口宽度自动决定
local FORCE_SCALE = nil

-- ── ASCII 字体 ──────────────────────────────────────────────────────────
-- 字形表只定义 1 倍大小,放大靠 scale_rows() 整数倍复制,所以改字体只需改这里。
-- 想换字样(比如改成 SNAKE)只需改下面 render() 的入参。
--
-- 字符用 █ 全角块:任何等宽字体都有这个字形,iPad 上走 mosh 不会变豆腐块。
-- 也正因为字形表里只有 █ 和空格(都是单宽字符),整数倍放大才是精确的。
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
-- 整幅画就不会因此错位(第一版 E 的中间行多一个空格,让第 3 行宽了 1 列)。
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
local BASE_WIDTH = width(HEADER[1])

--- 整数倍放大:每个字符横向重复 n 次,每行纵向重复 n 次。
-- 遍历必须按「字符」而不是按字节,否则 █(UTF-8 三字节)会被切碎。
local function scale_rows(rows, n)
  if n <= 1 then
    return rows
  end
  local out = {}
  for _, row in ipairs(rows) do
    local parts = {}
    for i = 0, vim.fn.strchars(row) - 1 do
      parts[#parts + 1] = vim.fn.strcharpart(row, i, 1):rep(n)
    end
    local wide = table.concat(parts)
    for _ = 1, n do
      out[#out + 1] = wide
    end
  end
  return out
end

--- 按窗口宽度挑一档倍率
local function pick_scale(win_w)
  if FORCE_SCALE then
    return FORCE_SCALE
  end
  if not ADAPTIVE then
    return 1
  end
  -- 2 倍要 102 列,再留 8 列边距,不够就退回 1 倍
  if win_w >= BASE_WIDTH * 2 + 8 then
    return 2
  end
  return 1
end

-- ── 入口 ────────────────────────────────────────────────────────────────
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

-- 让所有按钮等宽,文字就会左对齐成一列,而不是每行各自居中显得参差
local BUTTON_WIDTH = 0
for _, e in ipairs(ENTRIES) do
  BUTTON_WIDTH = math.max(BUTTON_WIDTH, width(e[1]) + #e[2])
end
BUTTON_WIDTH = BUTTON_WIDTH + 4

--- 按当前窗口大小现算一份布局
--
-- 垂直居中交给 alpha 自己的 group + position = 'v_center' 来做:
-- 它会拿真实窗口高度(state.win_height)算出偏移,比自己按 vim.o.lines
-- 估算准,也省掉一堆高度累加的算术(那套我第一版算错了 —— alpha 的
-- opts.spacing 是「每个元素后面都补空行」而不是「元素之间」,
-- 所以按钮组高度是 n*(1+spacing) 不是 n+(n-1)*spacing)。
local function build_layout()
  local win_w = vim.o.columns

  local scale = pick_scale(win_w)
  local header = scale_rows(HEADER, scale)

  -- 窗口窄到放不下字符画时,退回一行纯文字,避免被折行折断
  if win_w < BASE_WIDTH * scale + 4 then
    header = { "snake's neovim" }
  end

  -- 字形放大后按钮之间也要相应拉开,否则显得挤
  local spacing = scale >= 2 and 2 or 1

  local buttons = {
    type = 'group',
    val = vim.tbl_map(function(e)
      return {
        type = 'button',
        val = e[1],
        on_press = e[3],
        opts = {
          shortcut = e[2],
          -- shortcut 只负责「显示」,不绑按键 —— 必须另外给 keymap。
          -- 不写的话只有把光标移到按钮行上按回车才触发,直接按 n/f/r 没反应。
          -- alpha 会把这条 keymap 改成缓冲区局部,不会泄漏到别的缓冲区。
          keymap = { 'n', e[2], e[3], { noremap = true, silent = true, nowait = true } },
          position = 'center',
          cursor = 1,
          width = BUTTON_WIDTH,
          hl = 'SnakeDashboardButton',
          hl_shortcut = 'SnakeDashboardShortcut',
        },
      }
    end, ENTRIES),
    opts = { spacing = spacing },
  }

  local content = {
    {
      -- 注意是 text 不是 header:alpha 没有 'header' 这个类型
      type = 'text',
      val = header,
      opts = { position = 'center', hl = 'SnakeDashboardHeader' },
    },
    { type = 'padding', val = 2 },
    buttons,
    { type = 'padding', val = 1 },
  }

  -- 窗口太矮时把页脚去掉。alpha 的 v_center 只把偏移量夹到 0,
  -- 内容真放不下时它照样会被挤出屏幕底部,页脚首当其冲。
  -- 高度按 alpha 的实际排版规则算:按钮组是 n*(1+spacing)
  -- (spacing 是每个按钮后面都补空行,不是只在按钮之间补)。
  local win_h = math.max(1, vim.o.lines - vim.o.cmdheight)
  local content_h = #header + 2 + #ENTRIES * (1 + spacing) + 1 + 2
  if win_h >= content_h + 2 then
    content[#content + 1] = {
      type = 'text',
      val = { "snake's neovim", '按 <Space> 查看所有键位' },
      opts = { position = 'center', hl = 'SnakeDashboardFooter' },
    }
  end

  -- ADAPTIVE 关闭时就用一段固定留白把内容顶到偏上位置(原来的行为)
  if not ADAPTIVE then
    table.insert(content, 1, { type = 'padding', val = 2 })
    return { layout = content, opts = { margin = 5 } }
  end

  -- 整块内容包成一个 group,v_center 让它垂直居中
  return {
    layout = {
      {
        type = 'group',
        val = content,
        opts = { position = 'v_center' },
      },
    },
    opts = { margin = 5 },
  }
end

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
      -- 高亮一律用 link 跟随配色,换主题时会自动跟着变,不需要重新设置
      vim.api.nvim_set_hl(0, 'SnakeDashboardHeader', { link = 'Title' })
      vim.api.nvim_set_hl(0, 'SnakeDashboardButton', { link = 'Normal' })
      vim.api.nvim_set_hl(0, 'SnakeDashboardShortcut', { link = 'Special' })
      vim.api.nvim_set_hl(0, 'SnakeDashboardFooter', { link = 'Comment' })

      -- 隐藏 "type :help<Enter>..." 那行启动提示
      vim.opt.shortmess:append('I')

      local conf = build_layout()

      local aug = vim.api.nvim_create_augroup('snake_dashboard', { clear = true })

      -- 必须在 alpha.setup() 之前注册:autocmd 按注册顺序执行,
      -- 这样我们的回调先跑(按最终窗口尺寸重算布局),alpha 自己的
      -- VimEnter 回调随后才渲染,拿到的就是算好的布局。
      vim.api.nvim_create_autocmd('VimEnter', {
        group = aug,
        callback = function()
          conf.layout = build_layout().layout
        end,
      })

      -- 窗口大小变了就重算并重绘。
      -- 这里刻意不重新调用 alpha.setup():它内部会重建 VimEnter autocmd
      -- 和三个用户命令,反复调用没必要。直接改 default_config 里那份
      -- layout 再 redraw 就够了(redraw 读的就是这个表)。
      vim.api.nvim_create_autocmd('VimResized', {
        group = aug,
        callback = function()
          if vim.bo.filetype ~= 'alpha' then
            return
          end
          conf.layout = build_layout().layout
          pcall(require('alpha').redraw)
        end,
      })

      -- alpha 已经把行号、相对行号、符号列、cursorline 都关掉了,
      -- 但 laststatus 是**全局**选项,它管不了。我们在 options.lua 里设了
      -- 全局状态栏(laststatus=3),不处理的话启动界面底部会挂一条
      -- 显示 "alpha" 空缓冲区的状态栏,很难看。
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

      require('alpha').setup(conf)
    end,
  },
}
