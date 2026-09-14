-- snakenvim — 文件管理(yazi)
--
-- 【为什么从两个插件换成一个】
-- 2026-09-14 之前这里是 nvim-tree(常驻侧边栏)+ oil(把目录当缓冲区编辑)。
-- 两者职责重叠:浏览、移动、改名、打开,两边都在做。yazi 一个 TUI 文件管理器
-- 就能全覆盖,于是合并成一个入口,同时少两分依赖。
--
-- 【代价:功能对等,形态不等价 —— 这点得记着】
-- yazi 是**独立 TUI 窗口**,不是常驻侧边栏。所以 <Space>e 的行为从
-- 「开关左侧 32 列侧边栏」变成了「弹出一个文件管理器窗口」。
-- 随之而来:nvim-tree 的 <Space>E(在树里定位当前文件)没有对等物 ——
-- yazi 不是树,没有「定位」这个概念 —— 所以那个键一并删掉了。
--
-- 【键位:只留一个入口】
-- 本仓库踩过这个坑:曾经把文件树和 oil 都绑在 <Space>e 上,按第二次退不回去。
-- 现在只有一个:
--   <Space>e   打开 yazi,起在当前文件所在目录
-- 原本给 oil 的 `-` 已释放,回到 vim 内建行为(行首上移)。别再往这个键上加东西。
--
-- 【退出用 yazi 自己的 `q`,<Space>e 不做成切换】
-- 这个决定是权衡过的,别再"顺手"改回去:
--
--   1. yazi 里按 `q` 就退出,实测干净退回原文件。这也是 yazi 和 yazi.nvim
--      自己的约定 —— 插件的帮助文案写的就是 "q to close"。
--   2. yazi.nvim 根本没提供「关闭」这个能力:`plugin_keymaps` 的 8 个动作里
--      没有 close(只有分屏打开、grep、切目录等);`Yazi toggle` 的语义是
--      「恢复上次会话」而不是「关掉当前会话」。
--   3. 那能不能在 yazi 里把 <Space>e 绑成关闭?**不能,代价很实**:
--      <Space> 在 yazi 里是「选中文件」。一旦它成了某个映射的前缀,每次按
--      空格都要等 timeoutlen(400ms)才会送进 yazi —— 和当年 flash 与
--      mini.surround 抢 `s` 是同一类问题,等于用"选文件卡顿"换一次少按 `q`。
--
-- 【为什么懒加载用 VeryLazy 而不是 cmd】
-- 下面开了 open_for_directories,让 yazi 接管 `nvim <目录>`(取代 netrw)。
-- 这个能力靠 setup() 时注册的 BufAdd autocmd + 检查启动时的当前缓冲区实现,
-- 所以 setup() 必须在启动后尽快跑到。换成 cmd 懒加载的话,`nvim <目录>`
-- 永远等不到它 —— 这也是上游 README 对 open_for_directories 推荐 event 的原因。

return {
  {
    'mikavilpas/yazi.nvim',
    -- 插件仍在活跃开发(提交很密),锁稳定版:version='*' 取最新 tag,
    -- 而不是跟着 main 分支跑。
    version = '*',
    event = 'VeryLazy', -- 见上面注释,不能改成 cmd
    dependencies = {
      -- yazi.nvim 唯一的外部依赖,用于路径解析。
      -- 仓库里 plenary 已由 telescope 引入,这里只是声明关系,不会多装一份。
      { 'nvim-lua/plenary.nvim', lazy = true },
    },
    keys = {
      {
        '<leader>e',
        '<cmd>Yazi<cr>',
        desc = '文件管理:打开 yazi(当前文件所在目录)',
      },
    },
    opts = {
      -- 接管 `nvim <目录>`:直接开 yazi,而不是留一个空缓冲区或走 netrw。
      -- 配套必须在 init 里设 loaded_netrwPlugin(见下),否则 netrw 会抢先。
      open_for_directories = true,

      keymaps = {
        show_help = '<f1>', -- yazi 窗口里按 F1 看键位表
      },
    },
    init = function()
      -- 上游对 open_for_directories=true 明确推荐的配套写法:标记 netrw 已加载,
      -- 让它彻底不参与目录缓冲区,避免和 yazi 抢。
      -- lazy.nvim 的 init 在插件加载前就执行,所以这个标记来得及生效。
      -- (config/lazy.lua 里那段「netrw 故意保留」的注释已同步改写)
      vim.g.loaded_netrwPlugin = 1
    end,
  },
}
