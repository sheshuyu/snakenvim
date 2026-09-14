-- snakenvim — 环境自检
--
-- 用法:
--   :checkhealth snakenvim   完整检查(缺什么、怎么装)
--   :Snakenvim               一行行看当前状态
--
-- 放在 lua/snakenvim/ 而不是 lua/config/,是因为 nvim 的约定要求目录名和
-- :checkhealth 的命令名一致 —— 这样才会被识别成 :checkhealth snakenvim。

local M = {}

-- LSP 服务名 → 实际可执行文件名。两者不一致时,靠可执行文件判断安装状态会误报。
local lsp_bin = {
  clangd = 'clangd',
  pyright = 'pyright-langserver',
  lua_ls = 'lua-language-server',
  rust_analyzer = 'rust-analyzer',
  vtsls = 'vtsls',
  gopls = 'gopls',
  ts_ls = 'typescript-language-server',
}

-- ── 外部工具清单 ────────────────────────────────────────────────────────
-- mason 会自动装 LSP 和格式化器,所以那些不在这里列。
-- 这里只列「必须你自己装、配置无法代劳」的。
local function external_tools()
  return {
    {
      bin = 'git',
      why = '插件下载、gitsigns 的 diff 都依赖它',
      install = { win = 'https://git-scm.com/download/win', mac = 'brew install git' },
      required = true,
    },
    {
      bin = 'rg',
      why = 'telescope 的全文搜索',
      install = { win = 'scoop install ripgrep', mac = 'brew install ripgrep' },
      required = false,
    },
    {
      bin = 'fd',
      why = 'telescope 的文件查找',
      install = { win = 'scoop install fd', mac = 'brew install fd' },
      required = false,
    },
    {
      bin = 'tree-sitter',
      why = 'treesitter 安装 cpp / python 语法解析器(缺了就没有对应高亮)',
      -- mac 上要装的是 tree-sitter-cli:brew 的 tree-sitter 只有库,没有可执行文件
      install = { win = 'scoop install tree-sitter', mac = 'brew install tree-sitter-cli' },
      required = false,
    },
    {
      bin = 'cc',
      why = 'treesitter 编译解析器。Windows 上会退而检查 gcc/clang,通常已有',
      install = { win = 'scoop install gcc', mac = 'xcode-select --install' },
      required = false,
      alt = { 'gcc', 'clang', 'cl' },
    },
  }
end

local function find_tool(tool)
  if vim.fn.executable(tool.bin) == 1 then
    return tool.bin
  end
  for _, alt in ipairs(tool.alt or {}) do
    if vim.fn.executable(alt) == 1 then
      return alt
    end
  end
  return nil
end

--- 返回一个状态列表,供 :checkhealth 和 :Snakenvim 共用
function M.status()
  local profile = require('config.profile')
  local langs = require('config.langs')

  local out = {
    platform = profile.is_win and 'Windows' or (profile.is_mac and 'macOS' or 'Linux'),
    remote = profile.remote,
    mosh = profile.is_mosh,
    forced = profile.forced,
    clipboard = profile.clipboard,
    theme = require('config.theme').state.theme,
    icons = require('config.theme').state.icons,
    mosh_opts = require('config.theme').state.mosh_opts,
    tools = {},
    formatters = {},
    servers = langs.lsp_servers(),
    parsers = langs.parsers(),
  }

  for _, tool in ipairs(external_tools()) do
    out.tools[#out.tools + 1] = {
      tool = tool,
      found = find_tool(tool),
    }
  end

  -- 格式化器由 mason 装到自己的 bin 目录,运行时会被前置进 PATH。
  -- 注意用 mason_formatters()(mason 包名),不是 formatters()(conform 名)——
  -- 我们要查的是磁盘上的可执行文件,它和 mason 包名一致(clang-format / ruff / stylua)。
  for _, name in ipairs(langs.mason_formatters()) do
    out.formatters[#out.formatters + 1] = {
      name = name,
      bin = name,
      found = vim.fn.executable(name) == 1,
    }
  end

  return out
end

--- 生成可读的一行行状态
function M.summary()
  local s = M.status()
  local lines = {
    "snakenvim",
    ('  平台      : %s'):format(s.platform),
    ('  剪贴板    : %s%s'):format(
      s.clipboard,
      s.clipboard == 'osc52' and '(远程:y 会回到眼前的终端)' or '(本机)'
    ),
    ('  主题      : %s'):format(s.theme),
    ('  图标      : %s'):format(s.icons and '开启' or '关闭(ASCII)'),
    ('  mosh 优化 : %s'):format(s.mosh_opts and '开启' or '关闭'),
  }

  if s.forced then
    lines[#lines + 1] = ('  环境覆盖  : NVIM_PROFILE=%s'):format(s.forced)
  end

  lines[#lines + 1] = ('  LSP       : %s'):format(table.concat(s.servers, ', '))
  lines[#lines + 1] = ('  解析器    : %s'):format(table.concat(s.parsers, ', '))

  for _, f in ipairs(s.formatters) do
    lines[#lines + 1] = ('  格式化器  : %-14s %s'):format(f.name, f.found and '就绪' or '未安装(下次启动由 mason 安装)')
  end

  for _, t in ipairs(s.tools) do
    lines[#lines + 1] = ('  %-10s: %s'):format(t.tool.bin, t.found and ('就绪 (' .. t.found .. ')') or '缺失')
  end

  return lines
end

--- :checkhealth snakenvim 的入口
function M.check()
  local h = vim.health
  local s = M.status()

  -- 注意:这里不要再 h.start('snakenvim')。
  -- :checkhealth 的命令名本身已经生成了 "snakenvim:" 那个顶层标题,
  -- 再 start 一次同名小节会多出一层重复的空标题。
  h.start('环境')

  h.info('平台:' .. s.platform)
  if s.remote then
    h.info(('远程会话:是%s'):format(s.mosh and '(mosh)' or '(ssh)'))
    if s.clipboard == 'osc52' then
      h.info('剪贴板走 OSC52 —— y 的结果会回到你眼前的终端')
      h.info('若 iPad RootShell 不支持 OSC52,用 <Space>yc 改为送进 mac 本机剪贴板')
    end
  else
    h.info('远程会话:否,剪贴板使用系统原生方式')
  end
  if s.forced then
    h.info(('NVIM_PROFILE 覆盖生效:%s'):format(s.forced))
  end

  -- 主题
  h.start('主题与界面')
  h.info(('当前主题:%s'):format(s.theme))
  h.info(('图标:%s'):format(s.icons and '开启' or '关闭(ASCII)'))
  h.info('mosh 卡顿优化:' .. (s.mosh_opts and '开启' or '关闭'))

  -- 外部工具
  h.start('外部工具')
  local missing_required = {}
  for _, item in ipairs(s.tools) do
    local tool = item.tool
    if item.found then
      h.ok(('%s — 就绪 (%s)'):format(tool.bin, item.found))
    else
      local advice = tool.install[s.platform == 'macOS' and 'mac' or 'win']
      local msg = ('%s — 未找到。用途:%s。安装:%s'):format(tool.bin, tool.why, advice)
      if tool.required then
        h.error(msg)
        missing_required[#missing_required + 1] = tool.bin
      else
        h.warn(msg)
      end
    end
  end
  if #missing_required == 0 and vim.fn.executable('tree-sitter') == 0 then
    h.info('tree-sitter 缺失只影响 cpp / python 的 treesitter 高亮;')
    h.info('C 和 Lua 使用 nvim 自带的解析器,不受影响,且会自动回退到正则高亮。')
  end

  -- 格式化器
  h.start('格式化器(由 mason 安装)')
  for _, f in ipairs(s.formatters) do
    if f.found then
      h.ok(('%s — 就绪'):format(f.name))
    else
      h.info(('%s — 尚未安装,首次进入对应文件类型时由 mason 自动装'):format(f.name))
    end
  end

  -- LSP
  h.start('LSP 服务器(由 mason 安装)')
  h.info('配置的服务器:' .. table.concat(s.servers, ', '))
  local missing = {}
  for _, name in ipairs(s.servers) do
    -- LSP 的服务名和它的可执行文件名经常不一样,必须显式对应,
    -- 否则会误报「未就绪」(比如 lua_ls 的二进制叫 lua-language-server)
    local bin = lsp_bin[name] or name
    if vim.fn.executable(bin) == 1 then
      h.ok(('%s — 就绪 (%s)'):format(name, bin))
    else
      missing[#missing + 1] = name
    end
  end
  if #missing > 0 then
    h.info('尚未就绪:' .. table.concat(missing, ', ') .. '(首次打开对应文件时由 mason 自动安装)')
  end
  h.info('查看当前已附加的客户端::checkhealth vim.lsp')
end

return M
