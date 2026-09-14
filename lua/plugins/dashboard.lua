-- snakenvim — 启动界面
--
-- 用 alpha-nvim:它只提供 text / padding / button / group 四个布局原语,
-- 正好对应「一段 ASCII header + 几个入口」的需求,不夹带文件浏览器之类的
-- 重复功能(找文件我们已经有 telescope 了)。
--
-- 五个容易踩的坑(都踩过了):
--   1. 没有 type = 'header' 这种东西 —— header 就是 type = 'text'
--      ('header' 是 dashboard-nvim 的写法,混用会直接报
--       "attempt to call a nil value")
--   2. 按钮的 opts.shortcut 只负责显示,不会绑按键,必须另外给 opts.keymap
--   3. opts.shortcut 会被自动拼在 val 前面。想要完全掌控整行内容,
--      就把 shortcut 留空、自己拼进 val 里
--   4. alpha 的 opts.spacing 是「每个元素后面都补空行」而不是「元素之间」,
--      按钮组高度是 n*(1+spacing)
--   5. hl 的起止位置是直接交给 nvim_buf_add_highlight 的,那个 API 按**字节**
--      算,而我们的行里有 ▸ ┈ 和中文 —— 必须做字符到字节的换算,否则颜色串位
--
-- 布局每次按窗口大小现算,不是写死的:alpha 原生只从上往下排、不垂直居中,
-- 所以窗口一大内容就全挤在顶部、下面空一大片。

-- ── 可调项 ──────────────────────────────────────────────────────────────

-- 强制指定字样:'shadow'(立体,83 列)| 'block'(块体,51 列)| 'text'(纯文字)
-- nil = 按窗口宽度自动挑
local FORCE_HEADER = nil

-- 是否随窗口自适应(垂直居中、按宽度选字样、按高度决定要不要页脚)
local ADAPTIVE = true

-- 菜单每行的显示宽度。引导线把每行拉满,菜单才成为一个有分量的块,
-- 而不是五根飘在巨大 header 下面的小字。
local MENU_MIN_WIDTH = 40
local MENU_MAX_WIDTH = 60

-- ── ASCII 字体 ──────────────────────────────────────────────────────────

-- ANSI Shadow:█ 做填充,╔╗╚╝═║ 做棱边和投影,立体感来自字形本身。
-- 宽度 83 列 —— 别试图整数放大它:╔╗ 这类角字符一拉伸就散架
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

-- 块体,5 行,窄窗口用。笔画细、内部空隙多,所以不给它加投影 ——
-- 投影字符会填进字母的空隙里,看起来像噪点(试过,很丑)。
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

--- 从主题里取颜色。取不到就返回 nil,调用方走 link 回退。
local function theme_colors()
  local function fg_of(name)
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name })
    return ok and hl and hl.fg or nil
  end
  local bright = fg_of('Title') or fg_of('Function') or fg_of('Special')
  local normal = vim.api.nvim_get_hl(0, { name = 'Normal' })
  if not bright then
    return nil
  end
  return { bright = bright, bg = normal.bg or 0x000000 }
end

--- 给多行字符画生成「自上而下由亮到暗」的渐变高亮。
-- 每行一个高亮组;alpha 的 hl 支持按行、按列分段。
local function gradient_hl(n_rows, colors)
  if not colors then
    return 'SnakeDashboardHeader'
  end
  local hl = {}
  for i = 1, n_rows do
    local t = (i - 1) / math.max(1, n_rows - 1)
    -- 从 6% 混向背景,到 48% 混向背景 —— 顶部最亮,底部沉下去。
    -- 别混得太狠:超过 50% 时最下面一两行会糊进背景里,字母形状都看不清
    local name = ('SnakeDashboardHeader%d'):format(i)
    vim.api.nvim_set_hl(0, name, { fg = blend(colors.bright, colors.bg, 0.06 + 0.42 * t) })
    hl[i] = { { name, 0, -1 } }
  end
  return hl
end

--- 构造一个高亮分段。start/end 是**字符下标**,这里换算成字节偏移 ——
-- alpha 把它们直接交给 nvim_buf_add_highlight,那是按字节算的,
-- 而行里有 ▸ ┈ 和中文,不换算颜色会串位。
local function seg(line, group, c_start, c_end)
  return {
    group,
    #vim.fn.strcharpart(line, 0, c_start),
    c_end < 0 and -1 or #vim.fn.strcharpart(line, 0, c_end),
  }
end

-- ── 菜单 ────────────────────────────────────────────────────────────────

--- 拼一行菜单:▸ 标签 ┈┈┈┈┈┈ 快捷键
-- 引导线把每行拉满,菜单整体成为一个有分量的块,而不是几根飘在巨大
-- header 下面的小字。返回行内容和它的高亮分段。
--
-- 标签要补齐到统一宽度:不然「退出」这种两字标签的引导线会从很左边就开始,
-- 和别的行对不齐,看着像错位。
local function menu_row(label, shortcut, total_w, label_w)
  local left = '▸  ' .. label .. string.rep(' ', math.max(0, label_w - width(label)))
  local lw = width(left)
  local sw = width(shortcut)
  local dots = total_w - lw - sw - 2
  if dots < 2 then
    dots = 2
  end

  local line = left .. ' ' .. string.rep('┈', dots) .. ' ' .. shortcut
  local dot_start = lw + 1

  return line, {
    seg(line, 'SnakeDashboardButton', 0, lw),
    seg(line, 'SnakeDashboardLeader', dot_start, dot_start + dots),
    seg(line, 'SnakeDashboardShortcut', dot_start + dots + 1, -1),
  }
end

-- 最近一次算出来的菜单几何位置。选中条要按这个范围画,不能用整行高亮 ——
-- 菜单只有几十列,整行铺满会从屏幕最左拉到最右,和菜单完全脱节。
local MENU_GEOM = { left = 0, width = 0 }

-- 每项是 { 标签, 快捷键, 动作 }。标签不要带前缀符号,menu_row 会加。
local ENTRIES = {
  {
    '新建文件',
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
    '查找文件',
    'f',
    function()
      require('telescope.builtin').find_files()
    end,
  },
  {
    '最近打开的文件',
    'r',
    function()
      require('telescope.builtin').oldfiles()
    end,
  },
  {
    -- 用 :Oil 而不是 require('oil'):oil 是懒加载的,直接 require 会因为
    -- 模块还不在 runtimepath 上而失败。:Oil 命令由 lazy 在加载插件时创建,
    -- 调用它会自动触发加载。
    '打开配置目录',
    'c',
    function()
      vim.cmd('Oil ' .. vim.fn.fnameescape(vim.fn.stdpath('config')))
    end,
  },
  {
    '退出',
    'q',
    function()
      vim.cmd.quit()
    end,
  },
}

--- 按窗口宽度挑字样
local function pick_header(win_w)
  if FORCE_HEADER == 'text' then
    return { "snakenvim" }
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
  return { "snakenvim" }
end

--- 菜单宽度:跟着 header 走,让两者的宽度比例看起来是刻意设计的
local function menu_width(win_w, header_w)
  local w = math.max(MENU_MIN_WIDTH, math.min(header_w - 6, MENU_MAX_WIDTH))
  return math.min(w, win_w - 4)
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
  local mw = menu_width(win_w, width(header[1]))
  local spacing = 1

  -- 记下菜单的位置和宽度,选中条要照着画。
  -- left 的算法和 alpha 的 align_center 一致:(窗口宽 - 内容宽) / 2 向下取整
  MENU_GEOM.width = mw
  MENU_GEOM.left = math.floor((win_w - mw) / 2)

  -- 所有标签补齐到同一宽度,引导线才会对齐成一条竖线
  local label_w = 0
  for _, e in ipairs(ENTRIES) do
    label_w = math.max(label_w, width(e[1]))
  end

  local rows = vim.tbl_map(function(e)
    local line, hl = menu_row(e[1], e[2], mw, label_w)
    return {
      type = 'button',
      val = line,
      on_press = e[3],
      opts = {
        -- 不给 shortcut:整行内容已经自己拼好了,让 alpha 再拼一次会重复
        keymap = { 'n', e[2], e[3], { noremap = true, silent = true, nowait = true } },
        position = 'center',
        cursor = 0,
        hl = hl,
      },
    }
  end, ENTRIES)

  local menu = { type = 'group', val = rows, opts = { spacing = spacing } }

  local content = {
    {
      -- 注意是 text 不是 header:alpha 没有 'header' 这个类型
      type = 'text',
      val = header,
      opts = { position = 'center', hl = gradient_hl(#header, colors) },
    },
    { type = 'padding', val = 3 },
    menu,
  }

  -- 高度预算:页脚是可选项,窗口放不下就不放,
  -- 而不是让它被 alpha 挤出屏幕(它的 v_center 只把偏移量夹到 0)
  local header_h = #header
  local buttons_h = #ENTRIES * (1 + spacing)
  local want_footer = header_h + 3 + buttons_h + 5

  if win_h >= want_footer then
    -- 分隔线宽度跟菜单一致,把页脚和菜单绑成一个整体。
    -- 不这么做的话页脚只是两行小字按窗口居中,和上面几十列的菜单没有任何
    -- 视觉关联,看起来像飘在下面的一段孤立文字。
    content[#content + 1] = { type = 'padding', val = 1 }
    content[#content + 1] = {
      type = 'text',
      val = { string.rep('─', mw) },
      opts = { position = 'center', hl = 'SnakeDashboardSeparator' },
    }
    content[#content + 1] = { type = 'padding', val = 1 }
    content[#content + 1] = {
      type = 'text',
      val = { "snakenvim", '按 <Space> 查看所有键位' },
      opts = { position = 'center', hl = 'SnakeDashboardFooter' },
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
      -- 静态高亮:不随主题变,用 link 跟随配色即可
      vim.api.nvim_set_hl(0, 'SnakeDashboardButton', { link = 'Normal' })
      vim.api.nvim_set_hl(0, 'SnakeDashboardLeader', { link = 'Comment' })
      vim.api.nvim_set_hl(0, 'SnakeDashboardShortcut', { link = 'Special' })
      vim.api.nvim_set_hl(0, 'SnakeDashboardFooter', { link = 'Comment' })
      vim.api.nvim_set_hl(0, 'SnakeDashboardSeparator', { link = 'WinSeparator' })
      vim.api.nvim_set_hl(0, 'SnakeDashboardHeader', { link = 'Title' })
      -- 选中行:整行铺一层底色,像 telescope / fzf 的选中行
      vim.api.nvim_set_hl(0, 'SnakeDashboardSelected', { link = 'Visual' })

      -- 隐藏 "type :help<Enter>..." 那行启动提示
      vim.opt.shortmess:append('I')

      local conf = build_layout()
      local aug = vim.api.nvim_create_augroup('snakenvim_dashboard', { clear = true })

      --- 重算布局并重绘(窗口变化、换主题时用)
      local function relayout()
        if vim.bo.filetype ~= 'alpha' then
          return
        end
        conf.layout = build_layout().layout
        pcall(require('alpha').redraw)
      end

      -- 必须在 alpha.setup() 之前注册:autocmd 按注册顺序执行,
      -- 这样我们的回调先跑(按最终窗口尺寸重算布局),alpha 自己的
      -- VimEnter 回调随后才渲染,拿到的就是算好的布局。
      --
      -- 顺带说明:渐变颜色是从配色方案里取的,而插件配置阶段还没应用主题,
      -- 那次算出来的颜色是错的 —— 靠这次 VimEnter 的重算覆盖掉。
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
      vim.api.nvim_create_autocmd('VimResized', { group = aug, callback = relayout })
      vim.api.nvim_create_autocmd('ColorScheme', { group = aug, callback = relayout })

      -- ── 选中条 ──────────────────────────────────────────────────────
      -- 不用 cursorline:cursorline 会铺满整个屏幕宽度,而菜单只有几十列,
      -- 那条横杠会和菜单完全脱节(渲染出来看过,很怪)。
      -- 改用 extmark 只在菜单的列范围内铺底色,选中效果刚好框住菜单那一块。
      local sel_ns = vim.api.nvim_create_namespace('snakenvim_dashboard_sel')

      local function paint_selection()
        local buf = vim.api.nvim_get_current_buf()
        if vim.bo[buf].filetype ~= 'alpha' then
          return
        end
        vim.api.nvim_buf_clear_namespace(buf, sel_ns, 0, -1)

        local line_count = vim.api.nvim_buf_line_count(buf)
        local row = vim.api.nvim_win_get_cursor(0)[1] - 1
        if row < 0 or row >= line_count then
          return
        end
        -- 空白行不画(比如菜单上下的留白)
        local text = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ''
        if text:match('^%s*$') then
          return
        end

        local left = MENU_GEOM.left
        local right = left + MENU_GEOM.width
        -- extmark 的列是**字节**偏移,菜单行里有 ▸ ┈ 和中文,得换算
        vim.api.nvim_buf_set_extmark(buf, sel_ns, row, #vim.fn.strcharpart(text, 0, left), {
          end_col = #vim.fn.strcharpart(text, 0, right),
          hl_group = 'SnakeDashboardSelected',
          hl_eol = false,
        })
      end

      vim.api.nvim_create_autocmd('FileType', {
        group = aug,
        pattern = 'alpha',
        callback = function()
          -- laststatus 是**全局**选项,alpha 管不了。我们在 options.lua 设了
          -- 全局状态栏(laststatus=3),不处理的话启动界面底部会挂一条显示
          -- "alpha" 空缓冲区的状态栏,很难看。
          vim.o.laststatus = 0
          vim.schedule(paint_selection)
        end,
      })

      vim.api.nvim_create_autocmd({ 'CursorMoved', 'WinEnter' }, {
        group = aug,
        callback = paint_selection,
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
