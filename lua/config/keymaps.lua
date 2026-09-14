-- snake's neovim — 键位
--
-- leader 是空格。按 <Space> 会由 which-key 弹出分组提示,不用背。
-- 分组结构参照 AstroNvim / LazyVim 的惯例:
--   <leader>f 查找文件   <leader>b 缓冲区   <leader>c 代码
--   <leader>g Git        <leader>l LSP      <leader>u 界面
--   <leader>w 窗口/保存  <leader>x 列表      <leader>y 剪贴板
-- 插件专属键位写在各自的 plugins/ 文件里,这里只放与插件无关的通用键位。

local map = vim.keymap.set
local profile = require('config.profile')

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
map('n', '<S-h>', '<cmd>bprevious<CR>', { desc = '缓冲区:上一个' })
map('n', '<S-l>', '<cmd>bnext<CR>', { desc = '缓冲区:下一个' })
map('n', '<leader>bb', '<cmd>e #<CR>', { desc = '切换回上一个缓冲区' })
map('n', '<leader>bd', '<cmd>bdelete<CR>', { desc = '关闭当前缓冲区' })
map('n', '<leader>bo', '<cmd>%bdelete<CR>', { desc = '关闭其它所有缓冲区' })

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

-- 通过 mosh 连到 mac 时,y 默认走 OSC52 回到 iPad。
-- 如果 RootShell 不支持 OSC52,用这个键位直接送进 mac 本机的剪贴板。
if profile.remote and profile.is_mac then
  local function pbcopy(text)
    if text == nil or text == '' then
      vim.notify("snake's neovim:没有内容可复制", vim.log.levels.WARN)
      return
    end
    vim.fn.system({ 'pbcopy' }, text)
    if vim.v.shell_error == 0 then
      vim.notify(("snake's neovim:已复制到被连的 mac 剪贴板(%d 字节)"):format(#text))
    else
      vim.notify("snake's neovim:pbcopy 调用失败", vim.log.levels.ERROR)
    end
  end

  map('n', '<leader>yc', function()
    pbcopy(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n'))
  end, { desc = '复制整个文件到 mac 剪贴板' })

  map('v', '<leader>yc', function()
    vim.cmd('normal! "zy')
    pbcopy(vim.fn.getreg('z'))
  end, { desc = '复制选中内容到 mac 剪贴板' })
end

-- ── 界面(主题 / 图标 / 远程优化)──────────────────────────────────────
map('n', '<leader>ut', function()
  require('config.theme').pick()
end, { desc = '切换主题' })
map('n', '<leader>ui', function()
  require('config.theme').toggle_icons()
end, { desc = '图标 / ASCII 切换' })
map('n', '<leader>uo', function()
  require('config.theme').toggle_mosh_opts()
end, { desc = 'mosh 卡顿优化开关' })

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
-- 终端开在**当前文件所在目录**,所以打开 .c 文件后按 <Space>tt 就能直接
-- gcc xxx.c -o xxx && ./xxx,不用先 cd。
-- 收起时只隐藏窗口、不杀进程,下次打开还是同一个会话。
map('n', '<leader>tt', function()
  require('config.terminal').toggle()
end, { desc = '浮动终端:开关(开在当前文件目录)' })
map('n', '<leader>tT', function()
  require('config.terminal').restart()
end, { desc = '浮动终端:在当前文件目录重开' })
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = '终端:回到普通模式' })
