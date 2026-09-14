-- snake's neovim — 补全 / LSP / 格式化
--
-- 「装哪些服务器、哪些文件类型用哪个格式化器」全部来自 config/langs.lua,
-- 这里不重复声明清单 —— 加语言请改那个文件。

local theme = require('config.theme')
local langs = require('config.langs')

return {
  -- ── mason:工具安装器 ────────────────────────────────────────────────
  {
    'mason-org/mason.nvim',
    cmd = 'Mason',
    opts = { ui = { border = 'rounded' } },
  },

  -- ── nvim-lspconfig:只作为 lsp/<server>.lua 的配置源 ─────────────────
  -- 0.12 起不要再用 require('lspconfig'),那是废弃写法。
  -- 这里保留它,是因为 nvim 自身不带任何 server 的默认配置。
  {
    'neovim/nvim-lspconfig',
    dependencies = { 'mason-org/mason.nvim' },
  },

  -- ── mason-lspconfig:按 langs.lua 的清单自动装并启用 LSP ──────────────
  -- 注意:setup_handlers 在 v2 已经删掉了,现在用 ensure_installed + automatic_enable。
  -- 这几个插件不设 lazy:已知坑是延后加载会导致第一个缓冲区挂不上 LSP。
  {
    'mason-org/mason-lspconfig.nvim',
    dependencies = {
      'mason-org/mason.nvim',
      'neovim/nvim-lspconfig',
    },
    opts = {
      ensure_installed = langs.lsp_servers(),
      automatic_enable = true,
    },
  },

  -- ── mason-tool-installer:装格式化器(上面那个只管 LSP)──────────────
  -- 注意用 mason_formatters() 而不是 formatters():
  -- 前者给的是 mason 包名(clang-format),后者是 conform 的格式化器名(clang_format)。
  -- 这里要的是 mason 包名,传错了会报 "Cannot find package"。
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    dependencies = { 'mason-org/mason.nvim' },
    opts = {
      ensure_installed = langs.mason_formatters(),
      run_on_start = true,
      start_delay = 1000, -- 让启动先完成,别和 LSP 抢下载带宽
      auto_update = false,
    },
  },

  -- ── conform:格式化 ──────────────────────────────────────────────────
  -- 刻意不配 format_on_save:默认保存时不动你的代码,需要时手动触发。
  -- 想改成保存即格式化,把下面 opts 里加一行:
  --   format_on_save = { timeout_ms = 1000, lsp_format = 'fallback' },
  {
    'stevearc/conform.nvim',
    cmd = 'ConformInfo',
    keys = {
      {
        '<leader>cf',
        function()
          require('conform').format({ async = true, lsp_format = 'fallback' })
        end,
        desc = '格式化当前文件',
      },
    },
    opts = function()
      -- 从 langs.lua 推导「文件类型 → 格式化器」
      local by_ft = {}
      for ft, lang in pairs(langs.ft_map) do
        if lang.formatter then
          by_ft[ft] = { lang.formatter }
        end
      end
      return {
        formatters_by_ft = by_ft,
        default_format_opts = { lsp_format = 'fallback' },
      }
    end,
  },

  -- ── blink.cmp:补全 ──────────────────────────────────────────────────
  -- 必须锁 1.*:main 分支是 v2 破坏性重写,还在开发中。
  -- v1 会自动下载预编译的模糊匹配二进制,Windows 的 x86_64 / aarch64 都有。
  -- 已知 Windows 坑::Lazy update 时可能因 DLL 被占用报 EPERM,
  -- 更新插件前先把所有 nvim 实例关掉。
  {
    'saghen/blink.cmp',
    version = '1.*',
    dependencies = { 'rafamadriz/friendly-snippets' },
    opts = {
      keymap = { preset = 'default' },

      -- 图标关闭时不使用 Nerd Font 字形,补全菜单改显示文字种类
      appearance = { nerd_font_variant = theme.icons() and 'mono' or 'none' },

      sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },

      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 400 },
        menu = { draw = { treesitter = { 'lsp' } } },
        ghost_text = { enabled = false },
      },

      signature = { enabled = true },

      fuzzy = { implementation = 'prefer_rust_with_warning' },
    },
    opts_extend = { 'sources.default' },
  },
}
