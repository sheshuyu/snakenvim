-- snake's neovim — 状态栏与键位提示
--
-- 状态栏刻意**不使用任何图标字母**:诊断用 E/W/I/H 文字、分隔符留空。
-- 这样无论终端字体是否装了 Nerd Font,状态栏都不会出现豆腐块。

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
            statusline = { 'oil', 'checkhealth', 'lazy' },
          },
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = {
            { function() return "snake's nvim" end },
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
        { '<leader>u', group = '界面' },
        { '<leader>w', group = '窗口 / 文件' },
        { '<leader>x', group = '列表' },
        { '<leader>y', group = '剪贴板' },
      },
    },
  },
}
