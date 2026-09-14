-- snakenvim — lazy.nvim 自举
--
-- 第一次启动时自动把 lazy.nvim 拉下来,之后正常加载。
-- 插件本体装在 stdpath('data')/lazy,在仓库之外,所以 git pull 不会和插件文件冲突。

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    '--branch=stable',
    'https://github.com/folke/lazy.nvim.git',
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "snakenvim:lazy.nvim 下载失败,请检查网络或 git 是否可用。\n", 'ErrorMsg' },
      { out, 'WarningMsg' },
    }, true, {})
    return
  end
end

vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  spec = {
    { import = 'plugins' },
  },

  -- 关掉 luarocks 构建。
  -- 我们有 5 个插件(gitsigns / nvim-lspconfig / oxocarbon / plenary / telescope)
  -- 的仓库里带了 .rockspec,lazy 看到就会去装 luarocks 工具链(hererocks)并尝试构建。
  -- 在 Windows 上这个构建会失败,而失败后 lazy 会反复重试,最终抛出
  -- "Too many rounds of missing plugins" 并中断初始化。
  -- 这些插件的 Lua 文件直接从 git 检出就能正常工作,不需要 rocks 打包。
  rocks = { enabled = false },

  -- 不设 defaults.lazy:插件默认在启动时加载。
  -- 只有明确写了 lazy = true 或给了触发条件的才会延后 —— 主题插件就是这样处理的。

  -- 故意**不设** install.colorscheme:那是「装插件时安装界面用哪套配色」。
  -- 它会在启动过程中真的切一次配色,而主题记录逻辑只要在那时记下来,
  -- 你的主题就会被重置成它。让它保持 lazy 的默认值(habamax,不在我们
  -- 的主题列表里),记录逻辑就会忽略它。
  -- 代价只是安装界面的配色朴素一点,换来的是「你选的主题不会被悄悄改掉」。

  -- 不自动检查插件更新。改配置时更新插件最容易出意外(尤其 blink.cmp 在 Windows 上),
  -- 所以保持关闭,由你自己决定什么时候跑 :Lazy update。
  checker = { enabled = false },

  change_detection = { notify = false },

  ui = { border = 'rounded' },

  performance = {
    rtp = {
      -- 只关掉确定用不到的。
      --
      -- netrw 依然不列进这份名单,但它的角色变了。以前留着它是为了给
      -- `nvim <目录>` 一个兜底行为;现在这件事交给 yazi 了 ——
      -- 见 plugins/explorer.lua 的 open_for_directories,那边的 init 会设
      -- vim.g.loaded_netrwPlugin = 1 把 netrw 顶掉。上游推荐的也是这个变量,
      -- 而不是从 runtimepath 里摘掉它,所以这里跟着官方走。
      disabled_plugins = { 'gzip', 'tar', 'tohtml' },
    },
  },
})
