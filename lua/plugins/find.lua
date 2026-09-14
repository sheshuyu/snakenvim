-- snake's neovim — 模糊查找(telescope)
--
-- 选 telescope 而不是 fzf-lua:机器上没有 fzf 二进制,而 rg 和 fd 都已就绪。
-- telescope 是纯 Lua,不依赖外部可执行文件,两个平台表现一致。

return {
  {
    'nvim-telescope/telescope.nvim',
    cmd = 'Telescope',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
    },
    keys = {
      { '<leader>ff', function() require('telescope.builtin').find_files() end, desc = '查找文件' },
      { '<leader>fg', function() require('telescope.builtin').live_grep() end, desc = '全文搜索' },
      { '<leader>fw', function() require('telescope.builtin').grep_string() end, desc = '搜索光标下的词' },
      { '<leader>fb', function() require('telescope.builtin').buffers() end, desc = '切换缓冲区' },
      { '<leader>fr', function() require('telescope.builtin').oldfiles() end, desc = '最近打开的文件' },
      { '<leader>fd', function() require('telescope.builtin').diagnostics() end, desc = '诊断列表' },
      { '<leader>fs', function() require('telescope.builtin').lsp_document_symbols() end, desc = '当前文件的符号' },
      { '<leader>fS', function() require('telescope.builtin').lsp_workspace_symbols() end, desc = '整个项目的符号' },
      { '<leader>fh', function() require('telescope.builtin').help_tags() end, desc = '帮助文档' },
      { '<leader>fk', function() require('telescope.builtin').keymaps() end, desc = '所有键位' },
      { '<leader>fm', function() require('telescope.builtin').marks() end, desc = '标记位置' },

      -- AstroNvim 习惯:<leader>fn 是新建文件
      { '<leader>fn', '<cmd>enew<CR>', desc = '新建文件(空缓冲区)' },
      -- LazyVim 习惯:<leader>sn 是搜索 nvim 自己的配置
      { '<leader>sn', function()
        require('telescope.builtin').find_files({ cwd = vim.fn.stdpath('config') })
      end, desc = '编辑 nvim 配置' },
      -- 搜索组别名,照顾 AstroNvim 的 <leader>s 肌肉记忆
      { '<leader>sg', function() require('telescope.builtin').live_grep() end, desc = '全文搜索' },
      { '<leader>sw', function() require('telescope.builtin').grep_string() end, desc = '搜索光标下的词' },
    },
    opts = {
      defaults = {
        -- 提示符和光标都用纯 ASCII / 常见字符
        prompt_prefix = '> ',
        selection_caret = '> ',
        path_display = { 'smart' },
        sorting_strategy = 'ascending',
        layout_strategy = 'horizontal',
        borderchars = { '─', '│', '─', '│', '┌', '┐', '┘', '└' },
        file_ignore_patterns = {
          '%.git/',
          'node_modules/',
          '__pycache__/',
          '%.o$',
          '%.obj$',
          '%.exe$',
        },
        mappings = {
          i = {
            ['<C-j>'] = 'move_selection_next',
            ['<C-k>'] = 'move_selection_previous',
            ['<Esc>'] = 'close',
          },
        },
      },
      pickers = {
        find_files = { hidden = true },
        oldfiles = { only_cwd = false },
      },
    },
  },
}
