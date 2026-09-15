-- snakenvim — 顶栏、状态栏、缩进线与键位提示
--
-- 全部是**纯视觉元素**,所以都归在这个文件。
-- 顶栏(barbar)和状态栏(lualine)是一对:上面列 buffer,下面显示当前 buffer 的详情。
--
-- 状态栏刻意**不使用任何图标字母**:诊断用 E/W/I/H 文字、分隔符留空。
-- 缩进线用的是 `│`(U+2502,制表符区的方块绘制字符),不用 Nerd Font 私有区。
-- 顶栏同理:分隔符用 `▎`(U+258E)、修改标记用 `●`(U+25CF)、关闭按钮用 `×`(U+00D7),
-- 全是各个等宽字体都有的字符,**只有文件类型图标跟随 <Space>ui 的图标开关**。
-- 这样无论终端字体是否装了 Nerd Font,都不会出现豆腐块(参见 config/theme.lua
-- 里图标档位用的是同一套思路)。

local theme = require('config.theme')

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
          -- ⚠️ 必须显式关掉图标,否则本文件开头那句「状态栏不使用任何图标字母」
          -- 是假的。默认情况下这几个组件会画 Nerd Font 私有区字形:
          --   filetype  → 走 devicons,py 是 U+E606、md 是 U+F48A
          --   branch    → 分支符号
          --   diff      → 增删符号
          -- 实测:开着的时候光打开一个 .md 文件,渲染里就能扫出 2 个私有区码点。
          -- 关掉之后分组名、语言名仍以文字显示(见下面 diagnostics 的 E/W/I/H)。
          icons_enabled = false,
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

  -- ── barbar:顶栏 buffer 标签栏 ─────────────────────────────────────────
  -- 把所有打开的 buffer 列成一行标签,**同时也是状态栏(lualine)的上半身**:
  -- 顶栏回答「开了哪些文件」,状态栏回答「当前这个文件怎么样」。
  --
  -- 【为什么是 barbar 而不是 bufferline】
  -- 用户原本点名 bufferline.nvim,调研后换成 barbar,两条硬事实:
  --   1. **catppuccin 没有 bufferline 集成** —— 它的 69 个集成文件里只有
  --      barbar.lua,而且 `grep -rn "BufferLine"` 在 catppuccin 里零命中。
  --      用 bufferline 就得手写约 10 个高亮组才能接上 Trae 配色。
  --      barbar 的集成用的是 surface1/mantle/blue/yellow/red —— 全在
  --      colorschemes.lua 的 Trae 覆盖里,配色自动就对。
  --   2. **维护状态** —— bufferline 最后推送 2025-01(105 个开放 issue),
  --      barbar 最后推送 2026-06(35 个)。差距 20 个月 vs 3 个月。
  --
  -- 【图标策略:跟随 <Space>ui,但分隔符/修改标记/关闭按钮永远用通用字符】
  -- 只有 filetype 图标(devicons)跟随开关,其余三个都是各字体必有的字符:
  --   分隔符 ▎ U+258E 左四分之一块  修改 ● U+25CF 实心圆  关闭 × U+00D7 乘号
  -- barbar **默认的关闭按钮是 Nerd Font 私有区字形**,必须改掉。
  --
  -- 【auto_hide = false:顶栏常驻】
  -- 原来设的是 1,含义是「可见 buffer 数 ≤ 1 就整行隐藏」(上游 render.lua 里是
  -- `#buffers <= auto_hide` → `showtabline = 0`)。代价是**只开一个文件时顶栏完全
  -- 看不见** —— 而那恰恰是最常见的用法,于是很容易被当成「顶栏没实现」。
  -- barbar 的 setup() 会把 showtabline 设成 2 且此后不再改动(上游 barbar.lua 末尾),
  -- 所以设成 false 就等于常驻,不需要我们自己碰 showtabline。
  --
  -- 【代价与补救:启动界面那条空栏】
  -- showtabline 是**全局**选项,而 alpha 不在 barbar 的 buffer 列表里(exclude_ft
  -- 里有它),所以常驻之后首页顶上会多一条画不出东西的空栏。
  -- 补救写在下面的 config 里,而且是 setup **之后** —— 顺序不能反:
  -- alpha 是 lazy = false、**启动时**就加载的,它的 FileType alpha 早在 barbar
  -- (VeryLazy)之前就烧完了;那时即使设了 showtabline = 0,随后 barbar.setup()
  -- 也会把它设回 2。所以不能照抄 dashboard.lua 那对 laststatus autocmd 的做法 ——
  -- laststatus 只有 options.lua 在启动时写一次,没有第二个写入者,才没这个问题。
  {
    'romgrk/barbar.nvim',
    event = 'VeryLazy',
    -- ⚠️ 必须关掉 barbar 的自动 setup,否则它会用**空配置**setup 两次。
    --
    -- 原因在 barbar 自己的 `plugin/barbar.lua`(会被 rtp 自动 source):
    --     if vim.g.barbar_auto_setup ~= false then
    --       require('barbar').setup(options)   -- options 来自 g:bufferline,我们是 nil
    --     end
    -- 于是 lazy `packadd` 时先跑一次默认配置 → 立刻渲染一次 → 之后 lazy 才用
    -- 我们的 `opts` 再 setup。中间那次渲染是**用默认值画的**,后果:
    --   * ASCII 模式下 filetype 图标那时还是默认的 true,而 devicons 按图标开关
    --     没被加载 → 冒出一条「icons.filetype.enabled is set to true but
    --     nvim-web-devicons was not found」的警告(而且那句话里的 "true" 是
    --     硬编码的,不管你实际设成什么都会这么写,很容易误导)
    --   * 白渲染一次,多一次开销
    -- `init` 在插件加载**之前**跑,所以这里设的 g: 变量一定生效。
    init = function()
      vim.g.barbar_auto_setup = false
    end,
    -- ⚠️ 依赖必须**条件化**,不能写死 `dependencies = { 'nvim-web-devicons' }`:
    -- 那会强制加载 devicons,于是 editor.lua 里那句 `enabled = theme.icons()`
    -- 的门就白设了 —— 关掉图标后 telescope 依然会冒出图标。条件化正好复用
    -- 同一个开关,两处判断永远一致。
    dependencies = theme.icons() and { 'nvim-tree/nvim-web-devicons' } or {},
    keys = {
      -- 本仓库的约定是「插件专属键位写在插件自己的 keys 字段里」,所以这几个
      -- 从 config/keymaps.lua 移到了这里(那边已删)。两处都留会打架。
      { '<S-h>', '<cmd>BufferPrevious<CR>', desc = '顶栏:上一个 buffer(按视觉顺序)' },
      { '<S-l>', '<cmd>BufferNext<CR>', desc = '顶栏:下一个 buffer(按视觉顺序)' },
      { '<leader>bd', '<cmd>BufferClose<CR>', desc = '顶栏:关闭当前 buffer(不打乱窗口布局)' },
      { '<leader>bo', '<cmd>BufferCloseAllButCurrent<CR>', desc = '顶栏:关闭其它所有 buffer' },
      { '<leader>bp', '<cmd>BufferPick<CR>', desc = '顶栏:按字母跳转 buffer' },
    },
    opts = {
      -- 动画在 SSH / iPad 上是纯开销,默认却是 true
      animation = false,
      -- 常驻 —— 只开一个文件时也显示。首页那条空栏由下面的 config 单独处理。
      auto_hide = false,
      -- 右上角的 tabpage 计数。单窗口工作流用不上,而且它默认的分隔字形
      -- (BufferTabpagesSep)也不是通用字符
      tabpages = false,
      -- 不让这些临时 buffer 占一格。和 lualine 的 disabled_filetypes 同一思路。
      -- 注意这只影响**它们不作为标签出现**,它们照样能正常打开
      exclude_ft = { 'checkhealth', 'lazy', 'qf', 'help', 'alpha', 'yazi' },
      icons = {
        -- 唯一跟随图标开关的一项。关掉时 barbar 只画文字,不会留豆腐块
        filetype = { enabled = theme.icons() },
        -- 下面三项是 barbar 的默认值,显式写出来固定住 —— 免得将来上游改了
        -- 默认值我们跟着变成豆腐块
        separator = { left = '▎', right = '' },
        modified = { button = '●' },
        -- 关闭按钮:barbar 默认是私有区字形,换成 Latin-1 的乘号
        button = '×',
        -- 诊断只留错误和警告,图标用文字 E/W —— 和 lualine 的
        -- symbols = { error = 'E', warn = 'W', ... } 保持同一套惯例。
        --
        -- ⚠️ key 必须是 vim.diagnostic.severity.* 的**数字**,不能写字符串
        -- 'ERROR' / 'WARN'。源码里是 `icons.diagnostics[i]`,i 来自
        -- `ipairs(DEFAULT_DIAGNOSTIC_ICONS)`,而那张表就是按 severity 数字建的
        -- (ERROR=1 WARN=2 INFO=3 HINT=4)。写字符串键**不会报错、会被静默忽略**,
        -- 表现就是「配了诊断但顶栏上什么都不显示」。
        --
        -- 另外注意上游这四档**默认全是 enabled = false**,不显式打开就不会出现。
        -- 图标带一个尾随空格,和上游默认值的形状一致。
        -- 颜色不用管:barbar 从 DiagnosticSign* 取色,catppuccin 定义了那些组。
        diagnostics = {
          [vim.diagnostic.severity.ERROR] = { enabled = true, icon = 'E ' },
          [vim.diagnostic.severity.WARN] = { enabled = true, icon = 'W ' },
          [vim.diagnostic.severity.INFO] = { enabled = false },
          [vim.diagnostic.severity.HINT] = { enabled = false },
        },
      },
    },

    -- 接手 showtabline:首页(alpha)关掉顶栏,其余情况常驻。
    --
    -- 必须写在这里、而不是照抄 dashboard.lua 的 FileType autocmd,原因见上面
    -- 「代价与补救」那段:alpha 启动时就加载完了,那时设 0 会被随后的 setup() 设回 2。
    -- 这个 config 跑在默认的 require('barbar').setup() **之后**,所以纠正一定生效。
    config = function(_, opts)
      require('barbar').setup(opts)

      local function sync_tabline()
        vim.o.showtabline = vim.bo.filetype == 'alpha' and 0 or 2
      end

      -- 管住后续切换:从首页打开文件、或又退回首页
      vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter' }, {
        group = vim.api.nvim_create_augroup('snakenvim_tabline', { clear = true }),
        callback = sync_tabline,
      })

      -- 立即按当前缓冲区求值一次。启动时这一步就是「把首页那条空栏关掉」——
      -- 此刻正停在 alpha 的 dashboard buffer 上。
      sync_tabline()
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
        -- 远程卡顿优化开着时不启用。运行时切换在 config/theme.lua 的
        -- apply_remote_opts 里做 —— 那边用的是 require('ibl').update(),
        -- 只改 enabled 不碰这里的彩虹配色(用 setup 会把下面这组色重置掉)。
        enabled = not vim.g.snakenvim_remote_opts,
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
