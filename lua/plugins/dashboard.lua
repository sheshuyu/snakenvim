-- snake's neovim — 启动界面
--
-- 用 alpha-nvim:它只提供 text / padding / button / group 四个布局原语,
-- 正好对应「一段 ASCII header + 几个入口」的需求,不夹带文件浏览器之类的
-- 重复功能(找文件我们已经有 telescope 了)。
--
-- 四个容易踩的坑(都踩过了):
--   1. 没有 type = 'header' 这种东西 —— header 就是 type = 'text'
--      ('header' 是 dashboard-nvim 的写法,混用会直接报
--       "attempt to call a nil value")
--   2. 按钮的 opts.shortcut 只负责显示,不会绑按键,必须另外给 opts.keymap
--   3. 按钮的 val 里不要再写一遍快捷键字母,alpha 会自动把 shortcut 拼在前面
--   4. alpha 的 opts.spacing 是「每个元素后面都补空行」而不是「元素之间」,
--      按钮组高度是 n*(1+spacing)
--
-- 布局每次按窗口大小现算,不是写死的:alpha 原生只从上往下排、不垂直居中,
-- 所以窗口一大内容就全挤在顶部、下面空一大片。

-- ── 可调项 ──────────────────────────────────────────────────────────────

-- 强制指定字样:'shadow'(立体,83 列)| 'block'(块体,51 列)| 'text'(纯文字)
-- nil = 按窗口宽度自动挑
local FORCE_HEADER = nil

-- 是否随窗口自适应(垂直居中、按宽度选字样、按高度决定要不要装饰)
local ADAPTIVE = true

-- ── ASCII 字体 ──────────────────────────────────────────────────────────

-- ANSI Shadow:█ 做填充,╔╗╚╝═║ 做棱边和投影,立体感来自字形本身。
-- 两侧的 ║ ╗ ╚ 就是「投影」,所以看起来有厚度。
-- 宽度 83 列 —— 别试图整数放大它:╔╗ 这类角字符一拉伸就散架了
-- (不像 █ 可以精确复制),所以它只用原始尺寸。
local SHADOW_FONT = {
  S = { '███████╗', '██╔════╝', '███████╗', '╚════██║', '███████║', '╚══════╝' },
  N = { '███╗   ██╗', '████╗  ██║', '██╔██╗ ██║', '██║╚██╗██║', '██║ ╚████║', '╚═╝  ╚═══╝' },
  A = { ' █████╗ ', '██╔══██╗', '███████║', '██╔══██║', '██║  ██║', '╚═╝  ╚═╝' },
  K = { '██╗  ██╗', '██║ ██╔╝', '█████╔╝ ', '██╔═██╗ ', '██║  ██╗', '╚═╝  ╚═╝' },
  E = { '███████╗', '██╔════╝', '█████╗  ', '██╔══╝  ', '███████╗', '╚══════╝' },
  V = { '██╗   ██╗', '██║   ██║', '██║   ██║', '╚██╗ ██╔╝', ' ╚████╔╝ ', '  ╚═══╝  ' },
  I = { '██╗', '██║', '██║', '██║', '██║', '╚═╝' },
  M = { '███╗   ███╗', '████╗ ████║', '██╔████╔██║', '██║╚██╔╝██║', '██║ ╚═╝ ██║', '╚═╝     ╚═╝' },
}

-- 块体,5 行,窄窗口用。字少笔画细,所以不给它加投影 ——
-- 投影会填进字母内部的空隙,看起来像噪点(试过,很丑)。
local BLOCK_FONT = {
  S = { '█████', '█    ', '█████', '    █', '█████' },
  N = { '█   █', '██  █', '█ █ █', '█  ██', '█   █' },
  A = { ' ███ ', '█   █', '█████', '█   █', '█   █' },
  K = { '█   █', '█  █ ', '███  ', '█  █ ', '█   █' },
  E = { '█████', '█    ', '████  ', '█    ', '█████' },
  V = { '█   █', '█   █', '█   █', ' █ █ ', '  █  ' },
  I = { '███', ' █ ', ' █ ', ' █ ', '███' },
  M = { '█   █', '██ ██', '█ █ █', '█   █', '█   █' },
}

local WORD = 'SNAKENVIM'

-- ── 工具 ────────────────────────────────────────────────────────────────

local function width(s)
  return vim.fn.strdisplaywidth(s)
end

local function char_count(s)
  return vim.fn.strchars(s)
end

local function char_at(s, i)
  return vim.fn.strcharpart(s, i, 1)
end

--- 取一个字母的字形,并把每行补齐到该字母最宽的那一行。
-- 字形表是手写的,某行多一个少一个空格很容易发生 —— 补一次宽度,
-- 整幅画就不会因此错位。
local function glyph(font, ch)
  local g = font[ch]
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

--- 把文字渲染成字符画,再把所有行补齐到统一宽度
local function render(word, font)
  -- 字体高度 = 任意字形的行数(取最大值以防某个字形多一行)
  local height = 0
  for _, g in pairs(font) do
    height = math.max(height, #g)
  end

  local rows = {}
  for _ = 1, height do
    rows[#rows + 1] = ''
  end

  local first = true
  for i = 1, #word do
    local g = glyph(font, word:sub(i, i):upper())
    if g then
      for r = 1, height do
        rows[r] = rows[r] .. (first and '' or ' ') .. g[r]
      end
      first = false
    end
  end

  -- 去掉行尾空格再统一补齐:所有行等宽,居中时左偏移才一致
  local w = 0
  for i, r in ipairs(rows) do
    rows[i] = r:gsub('%s+$', '')
    w = math.max(w, width(rows[i]))
  end
  for i, r in ipairs(rows) do
    rows[i] = r .. string.rep(' ', w - width(r))
  end
  return rows
end

local HEADERS = {
  shadow = render(WORD, SHADOW_FONT),
  block = render(WORD, BLOCK_FONT),
}

--- 拼一条铺满窗口宽度的装饰线:左右放角饰,中间用 unit 周期重复填满。
-- 结尾不足一个周期的部分,用 unit 的前几个字符补上(而不是空格),
-- 这样图案是连续到右角饰的,不会留一道缝。
local function band_line(win_w, left, unit, right)
  local lw, uw, rw = width(left), width(unit), width(right)
  local fill = win_w - lw - rw
  if fill <= 0 then
    return left .. right
  end

  local n = math.floor(fill / uw)
  local used = n * uw
  local rem = fill - used

  local tail = ''
  if rem > 0 then
    -- unit 里每个字符都是单列宽,所以取前 rem 个字符正好补满
    tail = vim.fn.strcharpart(unit, 0, rem)
  end

  return left .. unit:rep(n) .. tail .. right
end

-- ── 颜色 ────────────────────────────────────────────────────────────────

local function blend(c1, c2, t)
  local function part(c, shift)
    return math.floor(c / 2 ^ shift) % 256
  end
  local r = math.floor(part(c1, 16) * (1 - t) + part(c2, 16) * t + 0.5)
  local g = math.floor(part(c1, 8) * (1 - t) + part(c2, 8) * t + 0.5)
  local b = math.floor(part(c1, 0) * (1 - t) + part(c2, 0) * t + 0.5)
  return r * 65536 + g * 256 + b
end

--- 从主题里取两个颜色作为渐变的端点。取不到就返回 nil,调用方走 link 回退。
local function theme_colors()
  local function fg_of(name)
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name })
    return ok and hl and hl.fg or nil
  end
  local bright = fg_of('Title') or fg_of('Function') or fg_of('Special')
  local accent = fg_of('Function') or fg_of('String') or fg_of('Number')
  local dim = fg_of('Comment') or fg_of('NonText')
  local normal = vim.api.nvim_get_hl(0, { name = 'Normal' })
  local bg = normal.bg or 0x000000
  if not bright then
    return nil
  end
  return { bright = bright, accent = accent or bright, dim = dim or accent or bright, bg = bg }
end

--- 给多行字符画生成「自上而下由亮到暗」的渐变高亮。
-- 每行一个高亮组,alpha 的 hl 支持按行、按列分段。
local function gradient_hl(n_rows, colors)
  if not colors then
    return 'SnakeDashboardHeader'
  end
  local hl = {}
  for i = 1, n_rows do
    local t = (i - 1) / math.max(1, n_rows - 1)
    -- 从 10% 混向背景,到 65% 混向背景 —— 顶部最亮,底部沉下去
    local name = ('SnakeDashboardHeader%d'):format(i)
    vim.api.nvim_set_hl(0, name, { fg = blend(colors.bright, colors.bg, 0.10 + 0.55 * t) })
    hl[i] = { { name, 0, -1 } }
  end
  return hl
end

--- 给单行装饰带生成「横向渐变」高亮(左右两端各取一个主题色)
local function band_hl(line, colors, segments)
  if not colors then
    return 'SnakeDashboardBand'
  end
  local n = char_count(line)
  local seg_w = math.max(1, math.ceil(n / segments))
  local hl = {}
  for i = 0, segments - 1 do
    local start = i * seg_w
    if start < n then
      local t = i / math.max(1, segments - 1)
      local name = ('SnakeDashboardBand%d'):format(i)
      vim.api.nvim_set_hl(0, name, { fg = blend(colors.accent, colors.dim, t) })
      hl[#hl + 1] = { name, start, math.min(start + seg_w, n) }
    end
  end
  return { hl }
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

--- 按窗口宽度挑字样
local function pick_header(win_w)
  if FORCE_HEADER == 'text' then
    return { "snake's neovim" }
  end
  if FORCE_HEADER == 'shadow' then
    return HEADERS.shadow
  end
  if FORCE_HEADER == 'block' then
    return HEADERS.block
  end
  if not ADAPTIVE then
    return HEADERS.block
  end
  -- 立体字样 83 列,再留 12 列边距
  if win_w >= width(HEADERS.shadow[1]) + 12 then
    return HEADERS.shadow
  end
  if win_w >= width(HEADERS.block[1]) + 8 then
    return HEADERS.block
  end
  return { "snake's neovim" }
end

--- 按当前窗口大小现算一份布局
--
-- 垂直居中交给 alpha 自己的 group + position='v_center':它拿的是真实窗口
-- 高度(state.win_height),比自己按 vim.o.lines 估算准。
local function build_layout()
  local win_w = vim.o.columns
  local win_h = math.max(1, vim.o.lines - vim.o.cmdheight)

  local header = pick_header(win_w)
  local colors = theme_colors()
  local spacing = 1

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
      opts = { position = 'center', hl = gradient_hl(#header, colors) },
    },
    { type = 'padding', val = 2 },
    buttons,
  }

  -- 高度预算:装饰是可选项,窗口放不下就先砍装饰再砍页脚,
  -- 而不是让它们被 alpha 挤出屏幕(它的 v_center 只把偏移量夹到 0)
  local header_h = #header
  local buttons_h = #ENTRIES * (1 + spacing)
  local body_h = header_h + 2 + buttons_h

  local want_footer = body_h + 1 + 2
  local want_bands = want_footer + 2 + 2 -- 上下各:装饰线 + 一行留白

  local with_footer = win_h >= want_footer
  local with_bands = win_h >= want_bands

  if with_footer then
    content[#content + 1] = { type = 'padding', val = 1 }
    content[#content + 1] = {
      type = 'text',
      val = { "snake's neovim", '按 <Space> 查看所有键位' },
      opts = { position = 'center', hl = 'SnakeDashboardFooter' },
    }
  end

  if with_bands then
    -- 上:四角 + 渐变带;下:四角 + 波浪线
    -- 左右角饰用 ╭╮╰╯,和 ANSI Shadow 字样的棱边风格一致
    local top = band_line(win_w, '╭─', '░▒▓█▓▒', '─╮')
    local bottom = band_line(win_w, '╰─', '▁▂▃▄▅▆▇█▇▆▅▄▃▂', '─╯')

    table.insert(content, 1, { type = 'padding', val = 1 })
    table.insert(content, 1, {
      type = 'text',
      val = { top },
      opts = { position = 'center', hl = band_hl(top, colors, 8) },
    })

    content[#content + 1] = { type = 'padding', val = 1 }
    content[#content + 1] = {
      type = 'text',
      val = { bottom },
      opts = { position = 'center', hl = band_hl(bottom, colors, 8) },
    }
  end

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
      -- 静态高亮:这些不随主题变,用 link 跟随配色即可
      vim.api.nvim_set_hl(0, 'SnakeDashboardButton', { link = 'Normal' })
      vim.api.nvim_set_hl(0, 'SnakeDashboardShortcut', { link = 'Special' })
      vim.api.nvim_set_hl(0, 'SnakeDashboardFooter', { link = 'Comment' })
      vim.api.nvim_set_hl(0, 'SnakeDashboardHeader', { link = 'Title' })
      vim.api.nvim_set_hl(0, 'SnakeDashboardBand', { link = 'Comment' })
      -- 选中行:整行铺一层底色,像 telescope / fzf 的选中行
      vim.api.nvim_set_hl(0, 'SnakeDashboardSelected', { link = 'Visual' })

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

      -- 渐变颜色是从当前配色方案里取的,换主题要重新算一遍并重绘。
      -- (VimEnter 时会重算一次,所以启动时拿到的一定是应用主题之后的颜色 ——
      --  插件配置阶段算的那次早于主题应用,颜色是错的,但会被这次覆盖掉。)
      vim.api.nvim_create_autocmd('ColorScheme', {
        group = aug,
        callback = function()
          if vim.bo.filetype ~= 'alpha' then
            return
          end
          conf.layout = build_layout().layout
          pcall(require('alpha').redraw)
        end,
      })

      -- alpha 把行号、符号列、cursorline 都关掉了,但 laststatus 是
      -- **全局**选项它管不了。我们在 options.lua 设了全局状态栏
      -- (laststatus=3),不处理的话启动界面底部会挂一条显示 "alpha"
      -- 空缓冲区的状态栏,很难看。
      --
      -- 同时在这里打开 cursorline 做「整行选中条」。alpha 是在设置
      -- filetype 之后才关 cursorline 的,所以必须 vim.schedule 推到它
      -- 设置完再改,否则会被它覆盖掉。
      vim.api.nvim_create_autocmd('FileType', {
        group = aug,
        pattern = 'alpha',
        callback = function()
          vim.o.laststatus = 0
          vim.schedule(function()
            -- winhighlight 只在当前窗口生效,不会污染别的缓冲区
            vim.wo.winhighlight = 'CursorLine:SnakeDashboardSelected'
            vim.wo.cursorline = true
          end)
        end,
      })

      vim.api.nvim_create_autocmd('BufEnter', {
        group = aug,
        callback = function()
          if vim.bo.filetype == 'alpha' then
            return
          end
          vim.o.laststatus = 3
          -- winhighlight 是**窗口局部**的,而 alpha 用的就是后面显示文件的那个
          -- 窗口。不还原的话 'CursorLine:SnakeDashboardSelected' 会一直跟着走,
          -- 让普通缓冲区里所有匹配括号之类的高亮都变样。
          if vim.wo.winhighlight == 'CursorLine:SnakeDashboardSelected' then
            vim.wo.winhighlight = ''
          end
          vim.wo.cursorline = true
        end,
      })

      require('alpha').setup(conf)
    end,
  },
}
