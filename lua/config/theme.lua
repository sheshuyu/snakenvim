-- snakenvim — 主题与图标
--
-- 设计要点:
--   * 5 套主题里只有「当前这套」在启动时加载,其余 4 套等你切换时才加载
--   * 换主题的方式不限 —— <Space>ut 选择器、手敲 :colorscheme 都会被记住
--   * 记录存在 stdpath('state'),也就是**每台机器各记各的**:
--     Windows 上选 kanagawa、iPad 上选 carbonfox,互不影响

local M = {}

-- ── 可选主题 ────────────────────────────────────────────────────────────
-- plugin 字段要和 plugins/colorschemes.lua 里 lazy 的 name 对上,
-- 否则按需加载时会找不到插件。
M.themes = {
  { id = 'kanagawa',   plugin = 'kanagawa.nvim',  scheme = 'kanagawa',         label = 'kanagawa · 深墨底 蓝紫点缀' },
  { id = 'oxocarbon',  plugin = 'oxocarbon.nvim', scheme = 'oxocarbon',        label = 'oxocarbon · 近纯黑 极简克制' },
  { id = 'catppuccin', plugin = 'catppuccin',     scheme = 'catppuccin-mocha', label = 'catppuccin · Trae 配色(近黑底 + 粉彩)' },
  { id = 'rose-pine',  plugin = 'rose-pine',      scheme = 'rose-pine',        label = 'rose-pine · 优雅紫调' },
  { id = 'carbonfox',  plugin = 'nightfox.nvim',  scheme = 'carbonfox',        label = 'carbonfox · 纯黑冷调' },
}

-- 默认主题。选 oxocarbon 而不是 kanagawa:后者的底色 #1f1f28 是偏蓝的
-- (B=40 而 R=G=31),整屏会泛蓝。oxocarbon 的底色 #161616 是真正中性的黑
-- (R=G=B=22),而且它本身就是单色主题,连强调色都不带蓝。
-- 其余几套(kanagawa #1f1f28、rose-pine #191724)底色都偏蓝。
-- (catppuccin 那一项已经被调成 Trae 配色,底色 #1a1b1d 也是中性黑。)
M.default_theme = 'oxocarbon'

-- ── 状态读写 ────────────────────────────────────────────────────────────
-- 存在 state 目录而不是仓库里,所以这个选择不会跟着 git 同步到另一台机器。
local state_path = vim.fn.stdpath('state') .. '/snakenvim.json'

local function read_state()
  local f = io.open(state_path, 'r')
  if not f then
    return {}
  end
  local content = f:read('*a')
  f:close()
  if not content or content == '' then
    return {}
  end
  local ok, data = pcall(vim.json.decode, content)
  return (ok and type(data) == 'table') and data or {}
end

local function write_state()
  local f = io.open(state_path, 'w')
  if not f then
    return
  end
  f:write(vim.json.encode(M.state))
  f:close()
end

M.state = read_state()
if type(M.state.theme) ~= 'string' then
  M.state.theme = M.default_theme
end
if type(M.state.icons) ~= 'boolean' then
  M.state.icons = true -- 默认开启,与电脑端一致
end
-- 兼容旧键名。这个开关原来叫 mosh_opts,改名后如果只读新键,那么已经存在的
-- 机器上那个值会被当成「从没设置过」而重置成默认关 —— 用户的选择在改名时
-- 被静默丢掉。多读一次旧键,迁移过来再继续。
if type(M.state.remote_opts) ~= 'boolean' then
  M.state.remote_opts = type(M.state.mosh_opts) == 'boolean' and M.state.mosh_opts or false
end

--- 当前是否使用图标(供 lualine 等插件读取)
function M.icons()
  return M.state.icons
end

-- ── 查找 ────────────────────────────────────────────────────────────────
function M.find(id)
  for _, t in ipairs(M.themes) do
    if t.id == id then
      return t
    end
  end
end

-- scheme 名 → 主题 id,用于从 ColorScheme 事件反查
local scheme_to_id = {}
for _, t in ipairs(M.themes) do
  scheme_to_id[t.scheme] = t.id
end

-- ── 应用 ────────────────────────────────────────────────────────────────

--- 按需加载主题插件,然后应用。id 省略时用记住的那套。
function M.apply(id)
  local t = M.find(id or M.state.theme)

  -- 存的主题不在我们的列表里(比如手动切到了 nvim 内置主题),直接照名字应用
  if not t then
    local name = id or M.state.theme
    if pcall(vim.cmd.colorscheme, name) then
      M.state.theme = name
    end
    return
  end

  -- 主题插件是 lazy 的,要用之前必须先加载
  pcall(function()
    require('lazy').load({ plugins = { t.plugin } })
  end)

  if not pcall(vim.cmd.colorscheme, t.scheme) then
    vim.notify(("snakenvim:主题 %s 应用失败"):format(t.id), vim.log.levels.WARN)
    return
  end
  M.state.theme = t.id
end

--- 图标 / ASCII 切换。
--
-- 注意:signs.text 必须是「严重级别 → 字符串」的表,不能传函数
-- (0.12 的 diagnostic.lua 会直接把它当表索引,报 attempt to index field 'text')。
--
-- 图标档位刻意用几何符号(U+2716/25B2/25A0/25CB)而不是 Nerd Font 私有区码点:
-- 这些字形在各种等宽字体里都有,所以默认开启图标也不会出现豆腐块。
-- 想让它们变成 Nerd Font 图标,把下面的码点换成对应私用区码点即可。
function M.apply_icons()
  local icons = M.state.icons
  local s = vim.diagnostic.severity

  vim.diagnostic.config({
    signs = {
      text = icons and {
        [s.ERROR] = vim.fn.nr2char(0x2716), -- ✖
        [s.WARN] = vim.fn.nr2char(0x25B2), -- ▲
        [s.INFO] = vim.fn.nr2char(0x25A0), -- ■
        [s.HINT] = vim.fn.nr2char(0x25CB), -- ○
      } or {
        [s.ERROR] = 'E',
        [s.WARN] = 'W',
        [s.INFO] = 'I',
        [s.HINT] = 'H',
      },
    },
  })

  -- » 和 · 属于 Latin-1,所有等宽字体都有
  vim.opt.listchars = icons and { tab = '» ', trail = '·', nbsp = '·' }
    or { tab = '> ', trail = '-', nbsp = '+' }

  -- lualine 的配置函数会读 M.icons(),刷新一下让它重新求值
  pcall(function() require('lualine').refresh() end)
end

--- 远程卡顿优化开关。默认关闭 —— 横屏 + 物理键盘下体验和本机接近,
-- 没必要默认牺牲 cursorline。真觉得远程操作发涩时再开。
--
-- 这几项都是「光标一动就重绘」的东西,在 SSH / mosh 链路上会被放大成发涩的手感:
--   cursorline          每次移动整行重绘
--   缩进线(ibl)         每次移动重绘缩进指示线
--   代码上下文头          mode='cursor',光标一动就要重算当前函数/类
--   updatetime           越小越频繁触发 CursorHold 类动作(诊断浮窗、引用高亮)
--
-- 刻意**不管彩虹括号**:它的开销是按缓冲区变化触发的,不属于「光标一动就重绘」,
-- 而且它只有按缓冲区的 API、没有全局开关。这不是漏做,别顺手补上。
function M.apply_remote_opts()
  local on = M.state.remote_opts
  vim.opt.cursorline = not on
  vim.opt.updatetime = on and 500 or 250
  vim.g.snakenvim_remote_opts = on -- 下面两个插件的 opts 会读它,决定初始状态

  -- 运行时切换。只在插件**已经加载**时才动手 —— 否则这里的 require 会把
  -- 懒加载的插件在启动时就提前拉起来,白白拖慢启动;而它们的 opts 已经读过
  -- 上面那个全局变量,初始状态本来就是对的。
  if package.loaded['ibl'] then
    -- ⚠️ 这里必须用 update,**不能用 setup**。ibl 的三个入口语义不同:
    --   setup     → set_config,     = 默认值 + 传入值(**会把彩虹配色重置掉**)
    --   update    → update_config,  = 当前配置 + 传入值 ← 要的是这个
    --   overwrite → overwrite_config
    -- 而且 enabled 是每次渲染时按缓冲区读的,所以 update 一下即时生效,不用重启。
    pcall(function() require('ibl').update({ enabled = not on }) end)
  end
  if package.loaded['treesitter-context'] then
    pcall(vim.cmd, on and 'TSContext disable' or 'TSContext enable')
  end
end

-- ── 交互命令 ────────────────────────────────────────────────────────────

--- 打开主题选择器(带实时预览)
function M.pick()
  -- 先把 5 套主题全部加载:否则 telescope 的 colorscheme 列表里
  -- 只会出现当前已加载的那一套,选不了别的
  pcall(function()
    require('lazy').load({ plugins = vim.tbl_map(function(t) return t.plugin end, M.themes) })
  end)

  local ok = pcall(function()
    require('telescope.builtin').colorscheme({ enable_preview = true })
  end)
  if not ok then
    vim.notify("snakenvim:telescope 尚未就绪,稍后重试", vim.log.levels.WARN)
  end
end

function M.toggle_icons()
  M.state.icons = not M.state.icons
  M.apply_icons()
  write_state()
  vim.notify(("snakenvim:图标 %s"):format(M.state.icons and '已开启' or '已关闭(改用 ASCII)'))
end

function M.toggle_remote_opts()
  M.state.remote_opts = not M.state.remote_opts
  M.apply_remote_opts()
  write_state()
  vim.notify(
    ("snakenvim:远程卡顿优化 %s"):format(M.state.remote_opts and '已开启(cursorline 关闭)' or '已关闭')
  )
end

-- ── 初始化 ──────────────────────────────────────────────────────────────

function M.setup()
  M.apply(M.state.theme)
  M.apply_icons()
  M.apply_remote_opts()
end

-- 换主题时只刷新 lualine 配色,不记录选择(原因见下面 VimLeavePre 那段)
vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('snakenvim_theme_track', { clear = true }),
  callback = function()
    pcall(function() require('lualine').refresh() end)
  end,
})

-- 记录选择:只在退出时做一次,而且**只认我们自己列表里的主题**。
--
-- 为什么不在 ColorScheme 事件里随手记:很多插件会在运行中临时切配色。
-- lazy.nvim 装插件时就会按 install.colorscheme 切一次 —— 它的默认值是
-- {"habamax"},而且会强制把 habamax 追加进列表,所以哪怕我们不配它,
-- 装插件时也一定会切。于是整条错误链是:
--
--   启动 → lazy 检测到缺插件 → 切成 habamax/kanagawa(触发 ColorScheme)
--        → 被监听记进 M.state.theme → theme.setup() 读到被污染的记录
--        → 你选的主题被重置
--
-- 这个 bug 真实发生过:主题改成 oxocarbon 后,只要装过一次插件,
-- 退出时就被写回旧值,表现得像「改了根本不生效」。
--
-- 只认列表内的主题就能让这些临时配色被忽略。
-- 代价:手动 `:colorscheme habamax` 这类列表外的主题不会被记住 ——
-- 相比「选择被莫名重置」,这个代价划算得多。
vim.api.nvim_create_autocmd('VimLeavePre', {
  group = vim.api.nvim_create_augroup('snakenvim_theme_persist', { clear = true }),
  callback = function()
    local name = vim.g.colors_name
    if name and name ~= '' then
      local id = scheme_to_id[name]
      if id then
        M.state.theme = id
      end
      -- 不在列表里就保持原样,不动 M.state.theme
    end
    write_state()
  end,
})

return M
