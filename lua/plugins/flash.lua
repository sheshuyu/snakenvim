-- snake's neovim — 屏幕内快速跳转(flash.nvim)
--
-- 和 LSP 跳转是两回事,互补:
--   flash        在「当前屏幕」上跳到任意位置 —— 输入一两个字符,所有匹配处
--                会标上字母标签,按标签直接跳过去
--   gd / gr      「跨文件」按语义跳(定义、引用)
--   <Space>lD…   LSP 的候选列表,同名符号多时挑着跳
--
-- ⚠️ 这里把 s 和 S 覆盖掉了 —— 那是 vim 自带的「替换字符」和「替换整行」。
-- 这是 flash 的社区标准键位(LazyVim 也一样),但确实丢了两个 vim 命令。
-- 想留住 s / S 的话,把下面 keys 里的 's' / 'S' 换成别的键(比如 'gs' / 'gS')。
--
-- 另外:s 被占用后,mini.surround 的前缀已经改成 gs(见 plugins/editor.lua),
-- 否则按 s 之后 vim 要等 timeoutlen 才能分辨你要哪个,每次都会卡一下。

return {
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    opts = {
      modes = {
        -- 用 / 搜索时也启用标签:输入几个字符后所有匹配处标上字母,
        -- 直接按标签跳过去,不用再 n/n/n 一个个挪
        search = { enabled = true },

        -- f / t / F / T 增强:高亮屏幕上所有同名字符并能直接跳。
        -- jump_labels 默认是关的,打开后按 fx 会给每个 x 标标签,
        -- 按标签就能跳过去(跨行也行)
        char = { enabled = true, jump_labels = true },
      },
    },
    keys = {
      -- 注意:rhs 必须写成 lua 函数(或 <cmd>lua ...<cr>`),不能写 `:lua`,
      -- 否则会破坏 . 重复
      { 's', mode = { 'n', 'x', 'o' }, function() require('flash').jump() end, desc = 'Flash:跳到任意位置' },
      { 'S', mode = { 'n', 'x', 'o' }, function() require('flash').treesitter() end, desc = 'Flash:按语法节点选' },
      { 'r', mode = 'o', function() require('flash').remote() end, desc = 'Flash:跨窗口跳' },
      { 'R', mode = { 'o', 'x' }, function() require('flash').treesitter_search() end, desc = 'Flash:语法节点搜索' },
      { '<C-s>', mode = 'c', function() require('flash').toggle() end, desc = 'Flash:开关搜索模式' },
    },
  },
}
