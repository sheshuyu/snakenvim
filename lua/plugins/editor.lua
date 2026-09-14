-- snakenvim — 语法高亮与编辑增强

local theme = require('config.theme')
local langs = require('config.langs')
local profile = require('config.profile')

return {
  -- ── 图标字形 ────────────────────────────────────────────────────────
  -- 只在图标开启时加载。关闭图标时不加载它,telescope / oil 自然就只显示文字,
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

      -- 缩进范围指示线
      require('mini.indentscope').setup({
        symbol = '│',
        options = { try_as_border = true },
      })
    end,
  },

  -- ── oil:把文件系统当普通缓冲区编辑 ──────────────────────────────────
  -- 打开目录后用普通编辑操作改名/删除/新建,保存时真正落盘。
  {
    'stevearc/oil.nvim',
    cmd = 'Oil',
    keys = {
      -- 只留一个入口:侧边文件树是 <Space>e,oil 是「把目录当缓冲区编辑」,
      -- 两者定位不同,不要都绑到 <Space>e 上(之前就是这么绑的,
      -- 结果按第二次只是重新打开,退不回去)
      { '-', '<CMD>Oil<CR>', desc = '用 oil 打开所在目录' },
    },
    opts = {
      columns = { 'icon' },
      view_options = { show_hidden = true },
      float = { border = 'rounded' },
      delete_to_trash = false, -- 直接删除。想用回收站改成 true
      skip_confirm_for_simple_edits = true,
      keymaps = {
        -- oil 默认没有「关闭」键位(只有 <C-c>),加一个 q 更符合直觉
        ['q'] = { 'actions.close', mode = 'n' },
      },
    },
  },
}
