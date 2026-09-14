-- snakenvim — 状态栏、缩进线与键位提示
--
-- 全部是**纯视觉元素**,所以都归在这个文件。
--
-- 状态栏刻意**不使用任何图标字母**:诊断用 E/W/I/H 文字、分隔符留空。
-- 缩进线用的是 `│`(U+2502,制表符区的方块绘制字符),不用 Nerd Font 私有区。
-- 这样无论终端字体是否装了 Nerd Font,都不会出现豆腐块(参见 config/theme.lua
-- 里图标档位用的是同一套思路)。

return {
  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    opts = function()
      local theme = require('config.theme')

      -- 当前缓冲区挂了哪些 LSP 客户端
      local function lsp_clients()
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        if #clients == 0 then
          return ''
        end
        local names = {}
        for _, c in ipairs(clients) do
          names[#names + 1] = c.name
        end
        return ' ' .. table.concat(names, ',')
      end

      return {
        options = {
          theme = 'auto', -- 跟随当前主题自带的 lualine 配色
          globalstatus = true,
          -- 分隔符全部留空:不依赖任何特殊字形
          component_separators = { left = '', right = '' },
          section_separators = { left = '', right = '' },
          disabled_filetypes = {
            -- yazi 是独立 TUI 窗口(filetype 就叫 yazi),底下再压一条状态栏
            -- 只是浪费一行;checkhealth / lazy 也是同理。
            statusline = { 'yazi', 'checkhealth', 'lazy' },
          },
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = {
            { function() return "snakenvim" end },
            'branch',
            'diff',
          },
          lualine_c = {
            {
              'filename',
              path = 1,
              symbols = { modified = ' ●', readonly = ' [只读]', unnamed = '[未命名]' },
            },
          },
          lualine_x = {
            {
              'diagnostics',
              symbols = { error = 'E', warn = 'W', info = 'I', hint = 'H' },
            },
            { lsp_clients, cond = function() return #vim.lsp.get_clients({ bufnr = 0 }) > 0 end },
            -- 图标关闭时给个可见提示,免得以为是配置坏了
            {
              function()
                return theme.icons() and '' or 'ASCII'
              end,
            },
          },
          lualine_y = { 'filetype' },
          lualine_z = { 'location' },
        },
      }
    end,
  },

  -- ── indent-blankline:彩虹缩进线 ───────────────────────────────────────
  -- 取代了之前的 mini.indentscope —— 两者都在同一列画竖线,留着会叠在一起。
  --
  -- 【彩虹是它原生支持的,不用另装插件】
  -- 只要给 indent.highlight 一串色组名,再用 HIGHLIGHT_SETUP 钩子把色组定义出来。
  -- 网上流传的 indent-rainbowline.nvim 只是帮你拼这份配置,而它 43 星、两年没
  -- 更新,没必要为这点事多一个依赖。
  --
  -- 【颜色取自 One Dark 官方调色板】
  -- 和新加的 onedarkpro 主题同源,切到那套主题时缩进线依然协调。
  -- 色组必须注册在 HIGHLIGHT_SETUP 钩子里 —— 这样每次换配色方案都会重设一遍,
  -- 否则切完主题色组会丢,缩进线全变成同一个颜色。
  {
    'lukas-reineke/indent-blankline.nvim',
    -- 上游要求显式指 main:插件仓库名和模块名不一致(模块叫 ibl)
    main = 'ibl',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = function()
      local hooks = require('ibl.hooks')
      local rainbow = {
        'SnakenvimRainbowRed',
        'SnakenvimRainbowYellow',
        'SnakenvimRainbowBlue',
        'SnakenvimRainbowOrange',
        'SnakenvimRainbowGreen',
        'SnakenvimRainbowViolet',
        'SnakenvimRainbowCyan',
      }
      hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
        vim.api.nvim_set_hl(0, 'SnakenvimRainbowRed', { fg = '#E06C75' })
        vim.api.nvim_set_hl(0, 'SnakenvimRainbowYellow', { fg = '#E5C07B' })
        vim.api.nvim_set_hl(0, 'SnakenvimRainbowBlue', { fg = '#61AFEF' })
        vim.api.nvim_set_hl(0, 'SnakenvimRainbowOrange', { fg = '#D19A66' })
        vim.api.nvim_set_hl(0, 'SnakenvimRainbowGreen', { fg = '#98C379' })
        vim.api.nvim_set_hl(0, 'SnakenvimRainbowViolet', { fg = '#C678DD' })
        vim.api.nvim_set_hl(0, 'SnakenvimRainbowCyan', { fg = '#56B6C2' })
      end)

      return {
        -- mosh 卡顿优化开着时不启用。运行时切换在 config/theme.lua 的
        -- apply_mosh_opts 里做 —— 那边用的是 require('ibl').update(),
        -- 只改 enabled 不碰这里的彩虹配色(用 setup 会把下面这组色重置掉)。
        enabled = not vim.g.snakenvim_mosh_opts,
        indent = {
          char = '│',
          highlight = rainbow,
        },
        scope = {
          enabled = true, -- 顶上 mini.indentscope 留下的作用域线,由它接管
          -- 上下划线标记关掉:它们依赖字体里行内下划线的位置,终端里经常是歪的
          show_start = false,
          show_end = false,
        },
      }
    end,
  },

  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = {
      preset = 'classic',
      -- 键位提示里的图标关掉:那些字形最容易缺
      icons = { mappings = false },
      spec = {
        { '<leader>b', group = '缓冲区' },
        { '<leader>c', group = '代码' },
        { '<leader>f', group = '查找' },
        { '<leader>g', group = 'Git' },
        { '<leader>l', group = 'LSP' },
        { '<leader>s', group = '搜索' },
        { '<leader>t', group = '终端' },
        { '<leader>u', group = '界面' },
        { '<leader>w', group = '窗口 / 文件' },
        { '<leader>x', group = '列表' },
        { '<leader>y', group = '剪贴板' },
      },
    },
  },
}
