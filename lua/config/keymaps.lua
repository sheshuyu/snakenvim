-- snakenvim — 键位
--
-- leader 是空格。按 <Space> 会由 which-key 弹出分组提示,不用背。
-- 分组结构参照 AstroNvim / LazyVim 的惯例:
--   <leader>f 查找文件   <leader>b 缓冲区   <leader>c 代码
--   <leader>g Git        <leader>l LSP      <leader>u 界面
--   <leader>w 窗口/保存  <leader>x 列表      <leader>y 剪贴板
-- 插件专属键位写在各自的 plugins/ 文件里,这里只放与插件无关的通用键位。

local map = vim.keymap.set

-- ── 插入模式快速退出 ────────────────────────────────────────────────────
-- 手不离开主键区就能回普通模式。代价是插入模式下打不出 "jk" / "jj" 这两个
-- 字母组合(中英文都极少见)。不想要的话删掉这两行即可。
map('i', 'jk', '<Esc>', { desc = '退出插入模式' })
map('i', 'jj', '<Esc>', { desc = '退出插入模式' })

-- ── 搜索高亮 ────────────────────────────────────────────────────────────
map({ 'n', 'v' }, '<Esc>', '<cmd>nohlsearch<CR><Esc>', { desc = '清除搜索高亮' })

-- ── 窗口 ────────────────────────────────────────────────────────────────
map('n', '<C-h>', '<C-w>h', { desc = '窗口:移到左边' })
map('n', '<C-j>', '<C-w>j', { desc = '窗口:移到下面' })
map('n', '<C-k>', '<C-w>k', { desc = '窗口:移到上面' })
map('n', '<C-l>', '<C-w>l', { desc = '窗口:移到右边' })
map('n', '<C-Up>', '<cmd>resize +2<CR>', { desc = '窗口:加高' })
map('n', '<C-Down>', '<cmd>resize -2<CR>', { desc = '窗口:减矮' })
map('n', '<C-Left>', '<cmd>vertical resize -2<CR>', { desc = '窗口:变窄' })
map('n', '<C-Right>', '<cmd>vertical resize +2<CR>', { desc = '窗口:变宽' })
map('n', '<leader>ws', '<C-w>s', { desc = '水平分屏' })
map('n', '<leader>wv', '<C-w>v', { desc = '垂直分屏' })
map('n', '<leader>wc', '<C-w>c', { desc = '关闭当前窗口' })
map('n', '<leader>wo', '<C-w>o', { desc = '只保留当前窗口' })
map('n', '<leader>wd', '<C-w>d', { desc = '窗口:显示光标下的诊断' })

-- ── 缓冲区 ──────────────────────────────────────────────────────────────
-- 大部分缓冲区键位现在归顶栏(barbar)了,按本仓库的约定写在 plugins/ui.lua
-- 的 keys 字段里,不在这里。移过去的有:
--   <S-h> / <S-l>        上一个 / 下一个(**按顶栏的视觉顺序**走)
--   <leader>bd           关闭当前(用 BufferClose,不会打乱窗口布局)
--   <leader>bo           关闭其它所有
--   <leader>bp           按字母跳转 buffer(新增的)
--
-- 留在下面这个,因为它和插件无关 —— `e #` 是 vim 内建的「切回上一个缓冲区」,
-- 语义和顶栏的 BufferPrevious 不一样(它跳的是 alternate file,不是相邻标签)。
map('n', '<leader>bb', '<cmd>e #<CR>', { desc = '切换回上一个缓冲区' })

-- ── 文件 ────────────────────────────────────────────────────────────────
map('n', '<C-s>', '<cmd>write<CR>', { desc = '保存' })
map('i', '<C-s>', '<cmd>write<CR><Esc>', { desc = '保存' })
map('n', '<leader>w', '<cmd>write<CR>', { desc = '保存' })
map('n', '<leader>q', '<cmd>quit<CR>', { desc = '退出' })
map('n', '<leader>qq', '<cmd>qa<CR>', { desc = '退出全部' })
map('n', '<leader>Q', '<cmd>qa!<CR>', { desc = '强制退出全部(丢弃未保存)' })

-- ── 移动 ────────────────────────────────────────────────────────────────
-- Alt+j / Alt+k 上下搬当前行(选中时搬整块)
map('n', '<A-j>', '<cmd>m .+1<CR>==', { desc = '当前行下移' })
map('n', '<A-k>', '<cmd>m .-2<CR>==', { desc = '当前行上移' })
map('v', '<A-j>', ":m '>+1<CR>gv=gv", { desc = '选中行下移' })
map('v', '<A-k>', ":m '<-2<CR>gv=gv", { desc = '选中行上移' })
map('v', 'J', ":m '>+1<CR>gv=gv", { desc = '选中行下移' })
map('v', 'K', ":m '<-2<CR>gv=gv", { desc = '选中行上移' })
-- 合并下一行,但光标留在原处
map('n', 'J', 'mzJ`z', { desc = '合并下一行' })
-- 跳转匹配时画面居中,省得手动 zz
map('n', 'n', 'nzzzv', { desc = '下一个匹配(居中)' })
map('n', 'N', 'Nzzzv', { desc = '上一个匹配(居中)' })
map('n', '<C-d>', '<C-d>zz', { desc = '向下翻半页(居中)' })
map('n', '<C-u>', '<C-u>zz', { desc = '向上翻半页(居中)' })
-- 可视模式下 > < 保持选中,可以连续缩进
map('v', '<', '<gv', { desc = '减少缩进(保持选中)' })
map('v', '>', '>gv', { desc = '增加缩进(保持选中)' })

-- ── 编辑 ────────────────────────────────────────────────────────────────
-- 删除不进寄存器(小写 x 删字符、X 删左边字符、c 改),避免覆盖刚复制的内容
map({ 'n', 'v' }, 'x', '"_x', { desc = '删除(不进寄存器)' })
map('n', 'X', '"_X', { desc = '删除左边字符(不进寄存器)' })
map('n', 'Y', 'y$', { desc = '复制到行尾' })

-- ── 剪贴板 ──────────────────────────────────────────────────────────────
map('x', '<leader>p', '"_dP', { desc = '粘贴(不覆盖寄存器)' })
map({ 'n', 'v' }, '<leader>y', '"+y', { desc = '复制到系统剪贴板' })
map('n', '<leader>Y', '"+Y', { desc = '复制整行到系统剪贴板' })

-- 这里原来还有一对 <leader>yc(直接调 mac 的 pbcopy),作为 OSC52 失效时的兜底。
-- 已删掉,因为**它的存在本身就是两台机器键位表不一致的来源** —— 它只在
-- 「远程 + mac」时注册,于是 mac 被 iPad 远程用时 which-key 会多列一项,Windows 上没有。
-- 远程时的剪贴板现在统一只走 OSC52(见 config/profile.lua 与 options.lua)。
-- 想加回来就在下面补一段 `if profile.remote and profile.is_mac then` 的映射
-- (需要同时把文件顶部的 `local profile = require('config.profile')` 加回来)。

-- ── 界面(主题 / 图标 / 远程优化)──────────────────────────────────────
map('n', '<leader>ut', function()
  require('config.theme').pick()
end, { desc = '切换主题' })
map('n', '<leader>ui', function()
  require('config.theme').toggle_icons()
end, { desc = '图标 / ASCII 切换' })
map('n', '<leader>uo', function()
  require('config.theme').toggle_remote_opts()
end, { desc = '远程卡顿优化开关' })

-- ── 诊断 ────────────────────────────────────────────────────────────────
map('n', '<leader>cd', vim.diagnostic.open_float, { desc = '诊断:显示当前行' })
map('n', '[d', function()
  vim.diagnostic.jump({ count = -1 })
end, { desc = '上一个诊断' })
map('n', ']d', function()
  vim.diagnostic.jump({ count = 1 })
end, { desc = '下一个诊断' })

-- ── 列表 ────────────────────────────────────────────────────────────────
map('n', '<leader>xl', '<cmd>lopen<CR>', { desc = '打开位置列表' })
map('n', '<leader>xq', '<cmd>copen<CR>', { desc = '打开快速修复列表' })

-- ── 终端 ────────────────────────────────────────────────────────────────
-- 浮动终端,自己实现的(见 config/terminal.lua),不装插件。
-- 终端开在**当前文件所在目录**,所以打开 .c 文件后按 <C-\> 就能直接
-- gcc xxx.c -o xxx && ./xxx,不用先 cd。
-- 收起时只隐藏窗口、不杀进程,下次打开还是同一个会话。
--
-- 【为什么是 <C-\> 而不是 <Space>tt】
-- 开终端是高频操作,<Space>tt 要按三个键太啰嗦,换成单键。
--
-- 为什么不选 <Space>t:那会让它变成映射前缀,每次按 <Space>t 都要等
-- timeoutlen(400ms)才能确定你是要开终端、还是要按 <Space>tT —— 和当年
-- flash / mini.surround 抢 `s` 是同一类问题。快捷键省下的时间还不够它等的。
--
-- <C-\> 的好处:不占任何字母、不当前缀、任何键盘布局都在同一位置。
-- 注意只在**普通模式**下绑定 —— 终端模式里 `<C-\><C-n>` 是 vim 内建的
-- 「回到普通模式」,那一串不能被抢走。终端里的收起键是 <C-q>,正好配成一对:
--   <C-\> 开(普通模式)   <C-q> 收(终端模式)
map('n', '<C-\\>', function()
  require('config.terminal').toggle()
end, { desc = '浮动终端:开关(开在当前文件目录)' })
map('n', '<leader>tT', function()
  require('config.terminal').restart()
end, { desc = '浮动终端:在当前文件目录重开' })
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = '终端:回到普通模式' })
