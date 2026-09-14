-- snake's neovim — 键位
--
-- leader 是空格。按 <Space> 会由 which-key 弹出分组提示,不用背。
-- 插件专属的键位写在各自的 plugins/ 文件里,这里只放与插件无关的通用键位。

local map = vim.keymap.set
local profile = require('config.profile')

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

-- ── 缓冲区 ──────────────────────────────────────────────────────────────
map('n', '<S-h>', '<cmd>bprevious<CR>', { desc = '缓冲区:上一个' })
map('n', '<S-l>', '<cmd>bnext<CR>', { desc = '缓冲区:下一个' })
map('n', '<leader>bd', '<cmd>bdelete<CR>', { desc = '关闭当前缓冲区' })
map('n', '<leader>bo', '<cmd>%bdelete<CR>', { desc = '关闭其它所有缓冲区' })

-- ── 文件 ────────────────────────────────────────────────────────────────
map('n', '<leader>w', '<cmd>write<CR>', { desc = '保存' })
map('n', '<leader>q', '<cmd>quit<CR>', { desc = '退出' })
map('n', '<leader>Q', '<cmd>qa!<CR>', { desc = '强制退出全部' })

-- ── 移动 ────────────────────────────────────────────────────────────────
-- 上下移动选中行,自动重新缩进
map('v', 'J', ":m '>+1<CR>gv=gv", { desc = '选中行下移' })
map('v', 'K', ":m '<-2<CR>gv=gv", { desc = '选中行上移' })
-- 合并下一行,但光标留在原处
map('n', 'J', 'mzJ`z', { desc = '合并下一行' })
-- 跳转匹配时画面居中,省得手动 zz
map('n', 'n', 'nzzzv', { desc = '下一个匹配(居中)' })
map('n', 'N', 'Nzzzv', { desc = '上一个匹配(居中)' })
map('n', '<C-d>', '<C-d>zz', { desc = '向下翻半页(居中)' })
map('n', '<C-u>', '<C-u>zz', { desc = '向上翻半页(居中)' })

-- ── 剪贴板 ──────────────────────────────────────────────────────────────
-- 行的粘贴不覆盖当前寄存器内容
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

-- ── 快速修复列表 ────────────────────────────────────────────────────────
map('n', '<leader>xl', '<cmd>lopen<CR>', { desc = '打开位置列表' })
map('n', '<leader>xq', '<cmd>copen<CR>', { desc = '打开快速修复列表' })
