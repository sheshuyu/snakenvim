-- snakenvim — LSP 配置
--
-- 这里只做两件事:
--   1. 所有 server 共用的行为(LspAttach 时挂键位、调诊断显示)
--   2. 个别 server 的少量微调
--
-- 「要装哪些 server、哪些文件类型用哪个」不在这里定义 —— 那在 config/langs.lua,
-- 由 mason-lspconfig 读取后自动安装并启用(见 plugins/coding.lua)。

local profile = require('config.profile')

-- ── 诊断显示 ────────────────────────────────────────────────────────────
-- 符号具体画什么由 config/theme.lua 的 apply_icons() 决定(支持切 ASCII),
-- 这里只定边框、来源等与图标无关的部分。
vim.diagnostic.config({
  virtual_text = { spacing = 2, prefix = '●' },
  severity_sort = true,
  float = { border = 'rounded', source = true },
  update_in_insert = false,
})

-- ── 个别 server 的微调 ──────────────────────────────────────────────────
-- clangd 故意不做任何编译参数干预:
-- 项目根目录有 compile_commands.json 时它自动使用,没有就按默认行为工作。
-- 所以这里不写 clangd 的配置。

-- lua_ls 需要知道 vim 是全局变量,否则写配置时会满屏 "undefined global vim"
vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      diagnostics = { globals = { 'vim' } },
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
    },
  },
})

-- ── 所有 server 共用的键位与行为 ────────────────────────────────────────
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('snakenvim_lsp_attach', { clear = true }),
  callback = function(args)
    local bufnr = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then
      return
    end

    -- 注意:0.12 起 vim.keymap.set 的选项键是 buf,不是 buffer
    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buf = bufnr, desc = desc, silent = true })
    end

    map('n', 'gd', vim.lsp.buf.definition, 'LSP:跳转定义')
    map('n', 'gD', vim.lsp.buf.declaration, 'LSP:跳转声明')
    map('n', 'gr', vim.lsp.buf.references, 'LSP:查找引用')
    map('n', 'gi', vim.lsp.buf.implementation, 'LSP:查找实现')
    map('n', 'K', vim.lsp.buf.hover, 'LSP:悬停文档')
    map('n', '<C-k>', vim.lsp.buf.signature_help, 'LSP:函数签名')
    map('n', '<leader>lr', vim.lsp.buf.rename, 'LSP:重命名符号')
    map({ 'n', 'v' }, '<leader>la', vim.lsp.buf.code_action, 'LSP:代码操作')
    map('n', '<leader>lf', function()
      vim.lsp.buf.format({ async = true })
    end, 'LSP:格式化(LSP 内置)')

    -- LazyVim / AstroNvim 习惯的别名,方便肌肉记忆
    map('n', '<leader>cr', vim.lsp.buf.rename, 'LSP:重命名符号')
    map({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, 'LSP:代码操作')
    map('n', '<leader>cl', '<cmd>checkhealth vim.lsp<CR>', 'LSP:查看客户端状态')

    -- ── 代码跳转 ────────────────────────────────────────────────────────
    -- gd / gr 是「直接跳过去」,这几个是「先列出候选再挑」,
    -- 同名符号多的时候后者好用得多
    map('n', '<leader>lD', function()
      require('telescope.builtin').lsp_definitions()
    end, 'LSP:定义列表(可挑选)')
    map('n', '<leader>lR', function()
      require('telescope.builtin').lsp_references()
    end, 'LSP:引用列表')
    map('n', '<leader>lI', function()
      require('telescope.builtin').lsp_implementations()
    end, 'LSP:实现列表')
    map('n', '<leader>lT', function()
      require('telescope.builtin').lsp_type_definitions()
    end, 'LSP:类型定义列表')
    -- 在竖直分屏里打开定义:想看被调用方又不想丢掉当前位置时用
    map('n', '<leader>lv', function()
      vim.cmd('vsplit')
      vim.lsp.buf.definition()
    end, 'LSP:分屏打开定义')
    -- 跳回上一个位置用 <C-o>,前进用 <C-i> —— 这两个是 vim 自带的跳转栈,
    -- 不需要额外映射(<C-i> 在终端里和 <Tab> 是同一个键码,抢它有风险)

    -- 高亮当前符号的所有引用,光标停一会自动出现
    if client:supports_method('textDocument/documentHighlight', bufnr) then
      local group = vim.api.nvim_create_augroup('snakenvim_lsp_highlight_' .. bufnr, { clear = true })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        group = group,
        buffer = bufnr,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        group = group,
        buffer = bufnr,
        callback = vim.lsp.buf.clear_references,
      })
    end
  end,
})
