-- snakenvim — 语法高亮与编辑增强
--
-- 高亮相关的都在这儿:devicons、treesitter、彩虹括号、代码上下文头。
-- 纯界面元素(状态栏、缩进线)在 plugins/ui.lua。

local theme = require('config.theme')
local langs = require('config.langs')
local profile = require('config.profile')

return {
  -- ── 图标字形 ────────────────────────────────────────────────────────
  -- 只在图标开启时加载。关闭图标时不加载它,telescope 自然就只显示文字,
  -- 不会留下任何缺字形的豆腐块。
  -- 注意:这项改动要重启 nvim 才完全生效(见 config/theme.lua 的 toggle_icons)。
  {
    'nvim-tree/nvim-web-devicons',
    enabled = theme.icons(),
    opts = {},
  },

  -- ── Treesitter:语法高亮 ─────────────────────────────────────────────
  -- 必须是 main 分支:master 分支的 README 明确写了不支持 Neovim 0.12。
  -- main 分支的 API 和网上流传的旧写法完全不同:
  --   * 没有 ensure_installed,改用 require('nvim-treesitter').install{}
  --   * 没有 highlight = { enable = true },改用 vim.treesitter.start()
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false, -- main 分支不支持懒加载
    build = ':TSUpdate',
    opts = { install_dir = vim.fn.stdpath('data') .. '/site' },
    config = function(_, opts)
      require('nvim-treesitter').setup(opts)

      -- tree-sitter 编译解析器时要调 C 编译器。在 Windows 上它会优先去找 MSVC 的
      -- cl.exe,没装 MSVC 就直接报 "Failed to execute the C compiler" 而失败 ——
      -- 哪怕 PATH 里明明有 gcc 也不会退而使用它。显式指定 CC 可以绕开这个坑。
      -- 环境里已经设了 CC 就尊重它,不覆盖。
      if not vim.env.CC or vim.env.CC == '' then
        if profile.is_win and vim.fn.executable('cl') == 0 then
          for _, cc in ipairs({ 'gcc', 'clang' }) do
            if vim.fn.executable(cc) == 1 then
              vim.env.CC = cc
              break
            end
          end
        end
      end

      local wanted = langs.parsers()

      -- 装解析器需要外部工具 tree-sitter-cli(≥0.26.1,不能用 npm 装)。
      -- 缺了不能让 nvim 起不来 —— 先检查,缺就只提示,不尝试安装。
      if vim.fn.executable('tree-sitter') == 0 then
        vim.schedule(function()
          vim.notify(
            table.concat({
              "snakenvim:未找到 tree-sitter-cli,cpp / python 的语法高亮暂不可用。",
              '其余功能一切正常,C 和 Lua 用的是 nvim 自带解析器,不受影响。',
              '安装后重启即可自动补上:',
              '  Windows:  scoop install tree-sitter',
              '  macOS:    brew install tree-sitter-cli',
              '            (注意:brew 的 tree-sitter 只装库,不带 CLI,必须装 -cli)',
              '详细状态::checkhealth snakenvim',
            }, '\n'),
            vim.log.levels.WARN
          )
        end)
      else
        pcall(function()
          require('nvim-treesitter').install(wanted)
        end)
      end

      -- 逐个缓冲区决定用哪种高亮
      local warned = {}
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('snakenvim_treesitter', { clear = true }),
        callback = function(args)
          local ft = vim.bo[args.buf].filetype

          -- pcall 是为了兼容:0.12 起 get_parser 不再抛异常而是返回 nil,
          -- 但包一层在旧版本上也安全
          local ok, parser = pcall(vim.treesitter.get_parser, args.buf)
          local has_parser = ok and parser ~= nil

          if has_parser then
            pcall(vim.treesitter.start, args.buf)
          else
            -- 回退:确保内置的正则语法高亮是开着的
            if ft ~= '' then
              vim.bo[args.buf].syntax = ft
            end
            -- 只对「我们确实声明过要解析器」的文件类型提示,避免打开杂项文件时刷屏
            if not warned[ft] and langs.for_ft(ft) then
              warned[ft] = true
              vim.schedule(function()
                vim.notify(
                  ("snakenvim:%s 已回退到内置正则高亮。装好 tree-sitter-cli 后重启,再执行 :TSInstall %s"):format(
                    ft,
                    ft
                  ),
                  vim.log.levels.WARN
                )
              end)
            end
          end
        end,
      })
    end,
  },

  -- ── 彩虹括号 ────────────────────────────────────────────────────────
  -- 按嵌套层级给括号/引号上不同颜色,treesitter 驱动。
  --
  -- 刻意**不挂到 mosh 卡顿开关**(<Space>uo)上:那个开关的定位是关掉
  -- 「光标一动就重绘」的东西,而这个插件的开销是按**缓冲区变化**触发的,
  -- 不属于那一类;而且它只有按缓冲区的 API
  -- (require('rainbow-delimiters').enable/disable(bufnr))、没有全局命令,
  -- 想全局禁用得遍历所有已开缓冲区、再额外处理后续新开的,不划算。
  {
    'HiPhish/rainbow-delimiters.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    -- 入口是 rainbow-delimiters.setup 而不是 rainbow-delimiters 本身
    -- (后者只暴露 enable/disable/toggle),所以不能用 opts,得显式 config
    config = function()
      require('rainbow-delimiters.setup').setup({})
    end,
  },

  -- ── 代码上下文头 ────────────────────────────────────────────────────
  -- 顶部吸附显示当前所在的函数/类签名,像 VSCode 的 sticky scroll。
  -- 光标移到函数内部就会看到;跨文件跳转后知道自己在哪一层,读代码很省事。
  {
    'nvim-treesitter/nvim-treesitter-context',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = function()
      return {
        -- mosh 卡顿优化开着时不启用。mode='cursor' 意味着**光标一移动就要
        -- 重算上下文**,正是那个开关要压制的东西。
        --
        -- 这里读一次决定初始状态;运行时的开关在 config/theme.lua 的
        -- apply_mosh_opts 里(那边只在插件已加载时才调 :TSContext,避免
        -- 为了切个开关就把懒加载的插件提前拉起来)。
        enabled = not vim.g.snakenvim_mosh_opts,
        mode = 'cursor',
        max_lines = 3, -- 别让它把顶部吃掉太多行
      }
    end,
  },

  -- ── mini.nvim:一次依赖覆盖多个小功能 ────────────────────────────────
  -- 只启用需要的模块,取代 nvim-autopairs / nvim-surround / Comment.nvim
  -- 三个独立插件,少两份依赖。
  {
    'echasnovski/mini.nvim',
    event = 'VeryLazy',
    config = function()
      -- 更强的文本对象:af/if 函数、ac/ic 类、aq/iq 引号等
      require('mini.ai').setup({ n_lines = 500 })

      -- 增删改包围符号,前缀用 gs:gsa 加、gsd 删、gsr 替换。
      -- mini.surround 默认前缀是 s,但 s 被 flash 占了(见 plugins/flash.lua)。
      -- 两者共存的话,按 s 之后 vim 要等 timeoutlen 才能分辨你是要 flash 还是
      -- surround,每次都会卡一下。改成 gs 前缀两者就不打架了(LazyVim 同样处理)。
      require('mini.surround').setup({
        mappings = {
          add = 'gsa',
          delete = 'gsd',
          find = 'gsf',
          find_left = 'gsF',
          highlight = 'gsh',
          replace = 'gsr',
          update_n_lines = 'gsn',
        },
      })

      -- 括号引号自动配对
      require('mini.pairs').setup()

      -- gc 注释、gcc 注释当前行
      require('mini.comment').setup()

      -- 浮动通知。setup 会把 vim.notify 接管掉,于是全仓库那些 vim.notify(...)
      -- 自动变成右上角浮窗 —— 顺带根治了「多行消息触发 Press ENTER」的老问题
      -- (命令行区域放不下多行,浮窗没这个限制)。
      --
      -- 选 mini.notify 而不是 rcarriga/nvim-notify:后者 ★3572 但一年没更新,
      -- 而 mini 这个零新增依赖,正合本文件开头那句「一次依赖覆盖多个小功能」。
      --
      -- 已知取舍:mini.nvim 是 event = 'VeryLazy',比 init.lua 里的 theme.setup()
      -- 晚,所以**启动阶段极早期**的通知仍走原生样式。实践中启动期只有
      -- 上面那个 tree-sitter 缺失提示(它走 vim.schedule),而 tree-sitter 已装好,
      -- 不会触发 —— 所以不为它调整 mini.nvim 的加载时机。
      --
      -- 把 max_width_share 从默认的 0.382 放宽到 0.6:默认值在 80 列的终端里
      -- 只有约 30 列宽,而 :Snakenvim 的状态摘要最长那几行有 40 列左右
      -- (比如「剪贴板 : osc52(远程:y 会回到眼前的终端)」),会被截断。
      -- 0.6 在 80 列下约 48 列,够用,也不会糊满整屏。
      require('mini.notify').setup({
        window = { max_width_share = 0.6 },
        -- 关掉 LSP 进度通知。它默认是开的,而 pyright 之类会疯狂上报
        -- 「N files to analyze (0%)」—— 是右上角刷屏的主要来源。
        -- LSP 有没有在干活,状态栏的客户端名和 :LspInfo 都能看,不需要弹窗。
        lsp_progress = { enable = false },
      })

      -- 注:缩进线曾经是这里的 mini.indentscope,现已换成 plugins/ui.lua 里的
      -- indent-blankline(彩虹缩进线)。两者都在同一列画竖线,留着会叠在一起。
    end,
  },
}
