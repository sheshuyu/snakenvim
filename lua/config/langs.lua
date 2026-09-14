-- snake's neovim — 语言单一数据源
--
-- 【加一门语言 = 往下面 M.languages 加一项】,四件事会自动跟着生效:
--   1. LSP 服务器  (lsp 字段)       → 交给 mason 自动安装并启用
--   2. 语法高亮    (parsers 字段)   → 交给 treesitter 自动安装
--   3. 格式化器    (formatter 字段) → 交给 mason 安装,conform 调用
--   4. 缩进        (indent 字段)    → 按文件类型自动设置
--
-- 不要再去改 config/lsp.lua 或 plugins/coding.lua —— 那边是从这张表推导的,
-- 改了会造成两份清单不同步。

local M = {}

M.languages = {
  {
    ft = { 'c', 'cpp' },
    lsp = 'clangd',
    parsers = { 'c', 'cpp' },
    formatter = 'clang_format',
    indent = 2,
  },
  {
    ft = 'python',
    lsp = 'pyright',
    parsers = { 'python' },
    formatter = 'ruff_format',
    indent = 4,
  },
  {
    ft = 'lua',
    lsp = 'lua_ls',
    parsers = { 'lua' },
    formatter = 'stylua',
    indent = 2,
  },

  -- ────────────────────────────────────────────────────────────────────
  -- 想加语言,照抄上面任意一项改字段即可。例如:
  --
  -- 汇编:只要高亮,不要 LSP(嵌入式汇编没有可用的 language server)
  -- { ft = { 'asm', 's' }, parsers = { 'asm' }, indent = 4 },
  --
  -- Rust:
  -- { ft = 'rust', lsp = 'rust_analyzer', parsers = { 'rust' },
  --   formatter = 'rustfmt', indent = 4 },
  --
  -- 前端:
  -- { ft = { 'javascript', 'typescript' }, lsp = 'vtsls',
  --   parsers = { 'javascript', 'typescript' }, formatter = 'prettier', indent = 2 },
  -- ────────────────────────────────────────────────────────────────────
}

-- ── 下面是推导逻辑,正常不需要改动 ──────────────────────────────────────

-- 文件类型 → 语言项 的查找表
M.ft_map = {}
for _, lang in ipairs(M.languages) do
  local fts = type(lang.ft) == 'table' and lang.ft or { lang.ft }
  for _, ft in ipairs(fts) do
    M.ft_map[ft] = lang
  end
end

--- 取某个文件类型对应的语言配置
function M.for_ft(ft)
  return M.ft_map[ft]
end

--- 去重收集某个字段(会把数组字段展平)
local function collect(field)
  local seen, out = {}, {}
  for _, lang in ipairs(M.languages) do
    local v = lang[field]
    if v then
      local items = type(v) == 'table' and v or { v }
      for _, item in ipairs(items) do
        if not seen[item] then
          seen[item] = true
          out[#out + 1] = item
        end
      end
    end
  end
  return out
end

--- 需要 mason 安装的 LSP 服务器清单
function M.lsp_servers()
  return collect('lsp')
end

--- 需要 treesitter 安装的 parser 清单
function M.parsers()
  return collect('parsers')
end

--- 需要 mason 安装的格式化器清单
function M.formatters()
  return collect('formatter')
end

return M
