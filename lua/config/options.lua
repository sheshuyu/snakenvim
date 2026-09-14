-- snake's neovim — 编辑器选项
--
-- 平台差异一律通过 config.profile 的开关判断,这里不直接写 is_windows 之类的判断。

local profile = require('config.profile')
local opt = vim.opt

-- ── 编码与文件格式 ──────────────────────────────────────────────────────
-- 两个平台统一:优先按 unix 处理,但读写 CRLF 文件不会报错(Windows 上会遇到)。
opt.encoding = 'utf-8'
opt.fileencoding = 'utf-8'
opt.fileformats = { 'unix', 'dos', 'mac' }

-- ── 外观 ────────────────────────────────────────────────────────────────
opt.number = true
opt.relativenumber = true
opt.signcolumn = 'yes' -- 常驻,避免 git 标记出现时整行左右抖动
opt.cursorline = true
opt.showmode = false -- 模式已经在状态栏里了,不必再占一行
opt.laststatus = 3 -- 全局状态栏,分屏时只有一个
opt.ruler = false
opt.termguicolors = profile.termguicolors
opt.fillchars = { eob = ' ' } -- 文件末尾不再是一列 ~
opt.list = true
opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
opt.winbar = '' -- 不用 winbar,保持顶部干净

-- ── 缩进 ────────────────────────────────────────────────────────────────
-- 这里是通用默认值;具体语言按文件类型覆盖,见 config/langs.lua
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.smartindent = true
opt.wrap = false

-- ── 搜索 ────────────────────────────────────────────────────────────────
opt.ignorecase = true
opt.smartcase = true -- 输入大写字母时自动区分大小写
opt.incsearch = true
opt.hlsearch = false -- 搜完不留高亮,按 Esc 也不用先清

-- ── 分屏 ────────────────────────────────────────────────────────────────
opt.splitright = true
opt.splitbelow = true
opt.splitkeep = 'screen' -- 分屏/关闭时画面不跳动

-- ── 编辑行为 ────────────────────────────────────────────────────────────
opt.swapfile = false
opt.backup = false
opt.undofile = true -- 关掉文件重开,仍然可以撤销
opt.updatetime = 250
opt.timeoutlen = 400
opt.confirm = true -- 有未保存改动时退出会问,而不是直接失败
opt.mouse = 'a'
opt.clipboard = 'unnamedplus' -- 具体走哪条通道由下面按 profile 决定
opt.scrolloff = 4
opt.sidescrolloff = 8
opt.pumheight = 12 -- 补全菜单最多 12 行,不遮挡代码
opt.completeopt = { 'menu', 'menuone', 'noselect' }

-- 撤销历史存到 state 目录。放在仓库外,所以不会跟着 git 同步到另一台机器
-- (路径本身是跨平台的,stdpath 会自动给出各平台正确的位置)
local undodir = vim.fn.stdpath('state') .. '/undo'
if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, 'p')
end
opt.undodir = undodir

-- ── Windows:用 pwsh 7 作为 :! 和 :terminal 的 shell ─────────────────────
-- 不改的话会退回 cmd.exe,在 :terminal 里很难用。
if profile.is_win and vim.fn.executable('pwsh') == 1 then
  opt.shell = 'pwsh'
  opt.shellcmdflag = '-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command'
  opt.shellquote = ''
  opt.shellxquote = ''
end

-- ── 剪贴板实际通道 ──────────────────────────────────────────────────────
-- 上面设的 clipboard = unnamedplus 只说明「用系统剪贴板」,具体走哪条通道
-- 由 profile 决定。远程(mosh/ssh)时改用 OSC52:让 y 的结果跟着 mosh 通道
-- 回到眼前的终端,而不是留在被连接的那台机器上 —— 不然在 iPad 上按 y
-- 是复制到了 mac 的剪贴板,粘贴时什么也得不到。
if profile.clipboard == 'osc52' then
  local osc52 = require('vim.ui.clipboard.osc52')
  vim.g.clipboard = {
    name = 'osc52',
    copy = {
      ['+'] = osc52.copy('+'),
      ['*'] = osc52.copy('*'),
    },
    paste = {
      ['+'] = osc52.paste('+'),
      ['*'] = osc52.paste('*'),
    },
  }
end
