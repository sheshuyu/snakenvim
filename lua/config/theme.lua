-- snake's neovim — 主题与图标
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
  { id = 'catppuccin', plugin = 'catppuccin',     scheme = 'catppuccin-mocha', label = 'catppuccin · 柔和低对比 (mocha)' },
  { id = 'rose-pine',  plugin = 'rose-pine',      scheme = 'rose-pine',        label = 'rose-pine · 优雅紫调' },
  { id = 'carbonfox',  plugin = 'nightfox.nvim',  scheme = 'carbonfox',        label = 'carbonfox · 纯黑冷调' },
}

M.default_theme = 'kanagawa'

-- ── 状态读写 ────────────────────────────────────────────────────────────
-- 存在 state 目录而不是仓库里,所以这个选择不会跟着 git 同步到另一台机器。
local state_path = vim.fn.stdpath('state') .. '/snake-nvim.json'

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
if type(M.state.mosh_opts) ~= 'boolean' then
  M.state.mosh_opts = false -- 默认关闭,觉得卡再开
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
    vim.notify(("snake's neovim:主题 %s 应用失败"):format(t.id), vim.log.levels.WARN)
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

--- mosh 卡顿优化开关。默认关闭 —— 横屏 + 物理键盘下体验和本机接近,
-- 没必要默认牺牲 cursorline。真觉得远程操作发涩时再开。
--
-- 这三项都是「光标一动就重绘」的东西,在 mosh 链路上会被放大成发涩的手感:
--   cursorline      每次移动整行重绘
--   indentscope     每次移动重绘缩进指示线
--   updatetime      越小越频繁触发 CursorHold 类动作(诊断浮窗、引用高亮)
function M.apply_mosh_opts()
  local on = M.state.mosh_opts
  vim.opt.cursorline = not on
  vim.opt.updatetime = on and 500 or 250
  vim.g.miniindentscope_disable = on
  vim.g.snake_mosh_opts = on
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
    vim.notify("snake's neovim:telescope 尚未就绪,稍后重试", vim.log.levels.WARN)
  end
end

function M.toggle_icons()
  M.state.icons = not M.state.icons
  M.apply_icons()
  write_state()
  vim.notify(("snake's neovim:图标 %s"):format(M.state.icons and '已开启' or '已关闭(改用 ASCII)'))
end

function M.toggle_mosh_opts()
  M.state.mosh_opts = not M.state.mosh_opts
  M.apply_mosh_opts()
  write_state()
  vim.notify(
    ("snake's neovim:mosh 卡顿优化 %s"):format(M.state.mosh_opts and '已开启(cursorline 关闭)' or '已关闭')
  )
end

-- ── 初始化 ──────────────────────────────────────────────────────────────

function M.setup()
  M.apply(M.state.theme)
  M.apply_icons()
  M.apply_mosh_opts()
end

-- 换主题时只记到内存,不写盘 —— telescope 预览会连续触发 ColorScheme,
-- 每次都写文件既浪费又没必要。真正的落盘放在退出时。
vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('snake_theme_track', { clear = true }),
  callback = function()
    local name = vim.g.colors_name
    if not name then
      return
    end
    -- 认得出就存 id,认不出就存原始名字(下次启动照样能用)
    M.state.theme = scheme_to_id[name] or name
    pcall(function() require('lualine').refresh() end)
  end,
})

vim.api.nvim_create_autocmd('VimLeavePre', {
  group = vim.api.nvim_create_augroup('snake_theme_persist', { clear = true }),
  callback = write_state,
})

return M
