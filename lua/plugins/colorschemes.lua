-- snakenvim — 5 套主题
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
    -- 必须 setup 之后 catppuccin-mocha 这个配色名才会注册出来。
    --
    -- ── 为什么这里有 color_overrides ──────────────────────────────────
    -- 这套色值是从用户本机 Trae CN 的实际配置里读出来的,不是猜的。
    -- Trae 当前主题是 icube-themes 扩展的 themes/dark_plus.json,但它的调色板
    -- 不是原版 VS Code Dark+,而是 icube 自己调过的「近黑中性底 + 柔和粉彩」:
    --   底色 #1a1b1d(中性灰,不偏蓝)、正文 #d1d3db、
    --   蓝 #80BBFF / 绿 #82D99F / 紫 #B38CFF / 粉 #F48CCA / 青 #81CFE0 / 橙 #F29D79
    --
    -- 选 catppuccin 做底子是因为它本身就是「柔和粉彩 + 深底」,和 Trae 最接近
    -- (数值比对:底色只差 17.7,蓝色只差 12.4)。再把这些槽位覆盖成 Trae 的精确
    -- 值,就基本对上了 —— 而且零新增依赖,catppuccin 本来就装着。
    --
    -- 前 15 个色值**直接来自 Trae 的 colorMap**;crust/surface2/subtext 那几个
    -- 是 Trae 没有对应概念、按灰阶插值出来的,影响很小。
    opts = {
      flavour = 'mocha',
      background = { dark = 'mocha' },
      color_overrides = {
        mocha = {
          -- 直接来自 Trae
          base = '#1a1b1d', -- editor.background
          mantle = '#17191a', -- editorGroupHeader.tabsBackground / tab.inactiveBackground
          surface0 = '#222427', -- activityBar / sideBar / titleBar.background
          surface1 = '#292c34', -- editor.lineHighlightBackground
          text = '#d1d3db', -- editor.foreground
          overlay2 = '#979aa4', -- editorLineNumber.foreground(较亮的灰)
          overlay1 = '#737780', -- 注释 token(较暗的灰)
          blue = '#80BBFF',
          green = '#82D99F',
          mauve = '#B38CFF',
          pink = '#F48CCA',
          teal = '#81CFE0',
          peach = '#F29D79',
          yellow = '#DED47E',
          red = '#F2858C',
          -- 灰阶插值(Trae 没有对应概念,按邻近槽位推算)
          crust = '#141517',
          surface2 = '#33363b',
          subtext1 = '#c2c5cd',
          subtext0 = '#a8abb3',
          -- overlay0 是**漏补的一个**,不是可有可无的:
          -- 它在 catppuccin 里被 20 个集成文件用到 —— NonText、FoldColumn、
          -- PmenuThumb、TabLine、LspCodeLens、FlashBackdrop、以及 barbar 的
          -- BufferInactive 等等。不补的话这些地方会露出 catppuccin 原版的
          -- #6c7086(冷紫灰),在一片中性灰里是唯一一块偏蓝的,很显眼。
          -- 取法:catppuccin 原梯度里 overlay0 落在 overlay1 和 surface2 之间,
          -- 这里按同样位置在 Trae 的 #737780 和 #33363b 之间取 30% 处。
          overlay0 = '#60646b',
        },
      },
      -- 下面不是调色板问题,是「槽位对应」的校准:catppuccin 把这几类语法元素
      -- 指到了别的颜色上,和 Trae 不一致。色值本身仍然来自上面的覆盖。
      custom_highlights = function(c)
        return {
          Comment = { fg = c.overlay1 }, -- Trae 注释是暗灰 #737780
          Number = { fg = c.pink }, -- Trae 数字是粉 #F48CCA
          Type = { fg = c.teal }, -- Trae 类型是青 #81CFE0
          Constant = { fg = c.blue }, -- Trae 常量(true/null 等)是蓝 #80BBFF
        }
      end,
    },
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
