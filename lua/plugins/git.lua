-- snakenvim — Git
--
-- 只做「显示改动 + 快速跳转/暂存」。不做完整的 Git 客户端界面,
-- 需要提交/推送时用 <Space>gg 直接开 lazygit(若装了)或 :terminal git。

return {
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
