-- snakenvim — Git
--
-- 分工,两个插件互补:
--   gitsigns   行内标记改动、暂存/撤销单个改动块。轻,常驻,不做完整界面
--   lazygit    <Space>gg 打开完整 TUI:提交、分支、rebase、推送
-- 日常改动用 gitsigns 就够,要提交或整理历史时进 lazygit。

return {
  -- ── lazygit:完整的 git TUI ────────────────────────────────────────────
  -- lazygit 本身是独立 TUI 程序(brew install lazygit),这个插件只负责把它
  -- 塞进浮动窗口。上游 README 自己就推荐绑 <leader>gg,和本文件原来的注释
  -- 承诺一致 —— 那个键以前只写在注释里、并没真的定义,这次一并兑现。
  {
    'kdheepak/lazygit.nvim',
    cmd = { 'LazyGit', 'LazyGitCurrentFile', 'LazyGitConfig', 'LazyGitFilter' },
    dependencies = { 'nvim-lua/plenary.nvim' },
    keys = {
      {
        '<leader>gg',
        function()
          -- 二进制缺失时给退路,别让按键直接抛错 —— 插件在但 CLI 不在是很常见的状态
          if vim.fn.executable('lazygit') == 1 then
            vim.cmd('LazyGit')
          else
            vim.notify(
              'snakenvim:未找到 lazygit,先退回终端。装它:brew install lazygit',
              vim.log.levels.WARN
            )
            vim.cmd('terminal git')
          end
        end,
        desc = 'Git:打开 lazygit(缺失时退回终端 git)',
      },
    },
  },

  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
      signs = {
        -- 全部用 ASCII,不依赖图标字体
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '^' },
        changedelete = { text = '~' },
        untracked = { text = '?' },
      },
      signs_staged = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '^' },
        changedelete = { text = '~' },
      },
      current_line_blame = false, -- 想看时按键触发,不常驻(常驻会拖慢远程操作)
      preview_config = { border = 'rounded' },
      on_attach = function(bufnr)
        local gs = require('gitsigns')
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buf = bufnr, desc = desc, silent = true })
        end

        -- 在改动块之间跳转
        map('n', ']c', function()
          if vim.wo.diff then
            vim.cmd.normal({ ']c', bang = true })
          else
            gs.nav_hunk('next')
          end
        end, 'Git:下一个改动块')
        map('n', '[c', function()
          if vim.wo.diff then
            vim.cmd.normal({ '[c', bang = true })
          else
            gs.nav_hunk('prev')
          end
        end, 'Git:上一个改动块')

        map('n', '<leader>gs', gs.stage_hunk, 'Git:暂存当前改动块')
        map('n', '<leader>gr', gs.reset_hunk, 'Git:撤销当前改动块')
        map('v', '<leader>gs', function()
          gs.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
        end, 'Git:暂存选中的改动块')
        map('n', '<leader>gS', gs.stage_buffer, 'Git:暂存整个文件')
        map('n', '<leader>gu', gs.undo_stage_hunk, 'Git:取消暂存当前改动块')
        map('n', '<leader>gp', gs.preview_hunk, 'Git:预览当前改动块')
        map('n', '<leader>gb', function()
          gs.blame_line({ full = true })
        end, 'Git:显示这一行的作者与提交')
        map('n', '<leader>gd', gs.diffthis, 'Git:查看本文件改动')
        map('n', '<leader>gt', gs.toggle_current_line_blame, 'Git:开关行内 blame')
      end,
    },
  },
}
