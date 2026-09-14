-- snake's neovim — 平台与远程环境探测
--
-- 【约定】整个配置只在这一个文件里判断平台和远程环境。
-- 其它文件一律读这里暴露的能力开关,不要自己写 os_uname() 或查环境变量。
-- 这样将来新增平台或改变远程策略,只需要改这一个文件。

local M = {}

-- ── 平台 ────────────────────────────────────────────────────────────────
local sysname = vim.uv.os_uname().sysname
M.is_win = sysname == 'Windows_NT'
M.is_mac = sysname == 'Darwin'
M.is_linux = sysname == 'Linux'

-- ── 远程会话 ────────────────────────────────────────────────────────────
-- mosh 会在服务端进程里写入 MOSH_CONNECTION / MOSH_IP;
-- iPad RootShell 通过 mosh 连到 mac 时,这些变量在 nvim 进程里可见。
M.is_mosh = vim.env.MOSH_CONNECTION ~= nil or vim.env.MOSH_IP ~= nil
M.is_ssh = vim.env.SSH_CONNECTION ~= nil or vim.env.SSH_TTY ~= nil
M.remote = M.is_mosh or M.is_ssh

-- 手动覆盖,便于在完整终端里模拟远程、或在 iPad 上强制本机行为:
--   NVIM_PROFILE=lite nvim   强制走远程分支
--   NVIM_PROFILE=full nvim   强制走本机分支
M.forced = vim.env.NVIM_PROFILE
if M.forced == 'full' then
  M.remote = false
elseif M.forced == 'lite' then
  M.remote = true
end

-- ── 剪贴板 ──────────────────────────────────────────────────────────────
-- 这是远程场景下唯一默认改变行为的地方,因为不改就是明确的错误结果:
-- 通过 mosh 操作 mac 上的 nvim 时,y 会把内容送进 **mac 的剪贴板**,
-- 而你眼前的是 iPad —— 粘贴时什么也得不到。
-- 走 OSC52 则顺 mosh 通道把内容回传给 iPad 终端,符合直觉。
M.clipboard = M.remote and 'osc52' or 'native'

-- ── 终端能力 ────────────────────────────────────────────────────────────
-- 真彩色:本机终端和 RootShell 都支持。COLORTERM 没被转发时按支持处理,
-- 因为回退到 256 色反而会让主题配色难看。
M.termguicolors = true

return M
