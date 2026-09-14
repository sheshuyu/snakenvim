-- snakenvim — 侧边文件树
--
-- 选 nvim-tree 而不是 neo-tree:最新提交都是 2026-09-07,都在活跃维护,
-- 但 nvim-tree 只依赖 nvim-web-devicons,neo-tree 还要多拉 nui 和 plenary
-- 两个包。跟这套配置的轻量取向更合。
--
-- 和 oil 的分工:
--   <Space>e  侧边文件树,固定 32 列,浏览/找文件用,不占你的编辑区
--   -         oil,把某个目录当普通缓冲区编辑,批量改名/建文件用
-- 两者不冲突:nvim-tree 关掉了 hijack_netrw,不去接管「打开目录」的行为。

return {
  {
    'nvim-tree/nvim-tree.lua',
    cmd = { 'NvimTreeToggle', 'NvimTreeFocus', 'NvimTreeFindFile' },
    keys = {
      { '<leader>e', '<cmd>NvimTreeToggle<CR>', desc = '文件树:开关' },
      { '<leader>E', '<cmd>NvimTreeFindFile<CR>', desc = '文件树:定位到当前文件' },
    },
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {
      -- 这两项都是「别去接管打开目录」的意思,默认值正好是反的:
      --   disable_netrw  默认 false
      --   hijack_netrw   默认 true —— 会把 nvim <目录> 的行为抢过来
      --   hijack_directories.enable 默认 true —— 同理
      -- 全关掉,目录的兜底行为留给 netrw,否则和 oil 互相抢
      disable_netrw = false,
      hijack_netrw = false,
      hijack_directories = { enable = false },

      view = {
        width = 32,
        side = 'left',
        preserve_window_proportions = true,
      },

      renderer = {
        group_empty = true,
        indent_markers = { enable = true },
        icons = {
          -- 图标开关跟着 <Space>ui 走(关掉时只显示文字,不会有豆腐块)
          show = { file = true, folder = true, git = true },
        },
      },

      filters = {
        dotfiles = false, -- 显示隐藏文件(配置文件里 .开头的一堆)
        custom = { '^%.git$', 'node_modules', '__pycache__', '%.o$', '%.obj$', '%.exe$' },
      },

      git = { enable = true, ignore = false },

      -- 在文件树里切换文件后,自动把光标定位到当前文件。
      -- 注意 update_root 是**表**不是布尔值(写 false 会报未知选项)
      update_focused_file = { enable = true, update_root = { enable = false } },

      actions = {
        open_file = {
          quit_on_open = false, -- 打开文件后保留文件树
          window_picker = { enable = false },
        },
      },
    },
  },
}
