-- snake's neovim — 5 套主题
--
-- 全部 lazy = true:启动时只有 config/theme.lua 里记住的那一套会被加载,
-- 其余 4 套等你按 <Space>ut 切换时才加载。
--
-- name 字段必须和 config/theme.lua 里 theme.plugin 的值一致,
-- 否则 theme.apply() 按需加载时会找不到插件。

return {
  {
    'rebelot/kanagawa.nvim',
    name = 'kanagawa.nvim',
    lazy = true,
    opts = {},
  },

  {
    'nyoom-engineering/oxocarbon.nvim',
    name = 'oxocarbon.nvim',
    lazy = true,
    -- oxocarbon 是纯 colorscheme 文件,没有 setup(),所以不给 opts
  },

  {
    'catppuccin/nvim',
    name = 'catppuccin',
    lazy = true,
    -- 必须 setup 之后 catppuccin-mocha 这个配色名才会注册出来
    opts = { flavour = 'mocha', background = { dark = 'mocha' } },
  },

  {
    'rose-pine/neovim',
    name = 'rose-pine',
    lazy = true,
    -- main 变体背景最深,最符合「黑色背景」的偏好
    opts = { variant = 'main', dark_variant = 'main' },
  },

  {
    'EdenEast/nightfox.nvim',
    name = 'nightfox.nvim',
    lazy = true,
    -- carbonfox 是 nightfox 系列里的纯黑变体
    opts = {},
  },
}
