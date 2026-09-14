# snake's neovim

一套精简、可跨平台同步的 Neovim 配置。Windows 和 macOS 共用同一份仓库,
Win11 上用 Windows Terminal、macOS 上也可能被 iPad 通过 mosh 远程使用。

23 个插件(对比 LazyVim 的 60+),没有成品发行版那层 abstraction,
每个文件都能直接读懂、直接改。

---

## 安装

两个平台各自把仓库 clone 到**该平台的配置目录**,靠 git 同步:

**Windows**

```powershell
git clone <仓库地址> "$env:LOCALAPPDATA\nvim"
```

**macOS**

```bash
git clone <仓库地址> ~/.config/nvim
```

然后直接开 `nvim`,首次启动会自动完成:

- 下载 lazy.nvim 和全部插件
- 由 mason 自动安装 LSP 服务器(clangd / pyright / lua_ls)和格式化器
- 安装 treesitter 语法解析器
- 生成 `lazy-lock.json`

> 目标目录必须不存在或为空,否则 `git clone` 会失败。

### 前置依赖

大部分工具由配置自动搞定,只有下面这些需要你自己装一次(每台机器一次):

| 工具 | 用途 | Windows | macOS |
|---|---|---|---|
| **git** | 下载插件 | [下载安装](https://git-scm.com/) | `brew install git` |
| **tree-sitter-cli** | 编译 cpp / python 语法解析器 | `scoop install tree-sitter` | `brew install tree-sitter` |
| **C 编译器** | 同上 | 通常已有(gcc/clang) | Xcode 命令行工具 |
| ripgrep | 全文搜索 | `scoop install ripgrep` | `brew install ripgrep` |
| fd | 文件查找 | `scoop install fd` | `brew install fd` |

**缺失不会导致 nvim 起不来。** 少了 `tree-sitter-cli` 时 cpp / python 会自动退回
内置的正则高亮并给出提示,C 和 Lua 用的是 nvim 自带解析器,不受影响。

随时用 `:checkhealth snake` 查看缺什么、怎么装,或 `:Snake` 看一行行状态速查。

---

## 日常使用

leader 键是**空格**。记不住键位时直接按 `<Space>`,which-key 会弹出分组提示。

分组结构参照 AstroNvim / LazyVim 的惯例,肌肉记忆可以直接迁移。

### 通用

| 键位 | 作用 |
|---|---|
| `jk` / `jj` | **退出插入模式**(手不离主键区) |
| `<C-s>` | 保存 |
| `<A-j>` / `<A-k>` | 上下搬当前行(可视模式下搬整块) |
| `Y` | 复制到行尾 |
| `x` / `X` | 删除(不进寄存器,不覆盖刚复制的内容) |
| `<C-h/j/k/l>` | 在窗口间移动 |
| `<C-d>` / `<C-u>` | 翻半页(画面居中) |
| `<Space>w` | 保存 |
| `<Space>q` / `<Space>qq` / `<Space>Q` | 退出 / 退出全部 / 强制退出 |
| `<Space>bb` | 切回上一个缓冲区 |
| `<Space>bd` / `<Space>bo` | 关闭当前 / 其它缓冲区 |
| `<Space>cd` | 显示当前行的诊断 |
| `[d` / `]d` | 上/下一个诊断 |
| `<Space>tt` | 打开终端(终端里 `<Esc><Esc>` 回到普通模式) |
| `<Space>fn` | 新建文件 |
| `<Space>sn` | **编辑 nvim 配置** |

> `jk` / `jj` 会占掉这两个字母组合,插入模式下打不出来。中英文里极少见,
> 不想要的话删掉 `keymaps.lua` 顶部那两行即可。

### 查找(`<Space>f`)

| 键位 | 作用 |
|---|---|
| `<Space>ff` | 查找文件 |
| `<Space>fg` | 全文搜索 |
| `<Space>fw` | 搜索光标下的词 |
| `<Space>fb` | 切换缓冲区 |
| `<Space>fr` | 最近打开的文件 |
| `<Space>fd` | 诊断列表 |
| `<Space>fs` / `<Space>fS` | 当前文件 / 整个项目的符号 |
| `<Space>fk` | 查看所有键位 |
| `<Space>fn` | 新建文件 |
| `<Space>sn` | **编辑 nvim 配置本身** |

> `<Space>sg` / `<Space>sw` 是 `<Space>fg` / `<Space>fw` 的别名,
> 照顾 AstroNvim 的 `<Space>s` 肌肉记忆。

### 代码(`<Space>c` / `<Space>l`)

| 键位 | 作用 |
|---|---|
| `<Space>cf` | 格式化当前文件(手动触发) |
| `gd` / `gD` | 跳转定义 / 声明 |
| `gr` | 查找引用 |
| `K` | 悬停文档 |
| `<Space>cr` / `<Space>lr` | 重命名符号(前者是 LazyVim 习惯) |
| `<Space>ca` / `<Space>la` | 代码操作(自动导入、快速修复) |
| `<Space>cl` | 查看 LSP 客户端状态 |
| `]c` / `[c` | 上/下一个 Git 改动块 |

### 界面(`<Space>u`)

| 键位 | 作用 |
|---|---|
| `<Space>ut` | **切换主题**(带实时预览,选择会被记住) |
| `<Space>ui` | 图标 / ASCII 切换 |
| `<Space>uo` | mosh 卡顿优化开关 |

---

## 启动界面

不带文件参数启动时(直接敲 `nvim`)显示自定义 dashboard;带参数启动时整个
插件都不加载,不影响启动速度。

```
        ███████╗ ███╗   ██╗  █████╗  ██╗  ██╗ ███████╗ ███╗   ██╗
        ██╔════╝ ████╗  ██║ ██╔══██╗ ██║ ██╔╝ ██╔════╝ ████╗  ██║
        ███████╗ ██╔██╗ ██║ ███████║ █████╔╝  █████╗   ██╔██╗ ██║
        ╚════██║ ██║╚██╗██║ ██╔══██║ ██╔═██╗  ██╔══╝   ██║╚██╗██║
        ███████║ ██║ ╚████║ ██║  ██║ ██║  ██╗ ███████╗ ██║ ╚████║
        ╚══════╝ ╚═╝  ╚═══╝ ╚═╝  ╚═╝ ╚═╝  ╚═╝ ╚══════╝ ╚═╝  ╚═══╝


              ▸  新建文件 ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈ n
              ▸  查找文件 ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈ f
              ▸  最近打开的文件 ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈ r
              ▸  打开配置目录 ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈ c
              ▸  退出 ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈ q


                        snake's neovim
                        按 <Space> 查看所有键位
```

| 键 | 作用 |
|---|---|
| `n` | 新建文件(输入路径) |
| `f` | 查找文件 |
| `r` | 最近打开的文件 |
| `c` | 打开配置目录(用 oil,可直接编辑) |
| `q` | 退出 |

把光标移到某一行按回车也可以。这些快捷键**只在该界面内生效**,不会污染其它缓冲区。

### 视觉效果

- **立体字样**用 ANSI Shadow: `█` 做填充,`╔╗╚╝═║` 做棱边和投影,
  立体感来自字形本身而不是特效
- **颜色是渐变**:header 自上而下由亮到暗(模拟顶部打光),端点颜色从当前
  配色方案里取(实测 kanagawa 出蓝、oxocarbon 出灰白),换主题会自动跟着变
- **菜单用引导线拉满**:每行做成 `▸ 标签 ┈┈┈┈ 快捷键` 的完整条目,
  而不是几根飘在巨大 header 下面的小字 —— 菜单整体成为一个有分量的块
- **选中行整行铺底色**,像 telescope / fzf 的选中行,一眼能看到选的是哪个

### 自适应行为

布局不是写死的,每次按窗口大小现算:

| 窗口宽度 | 表现 |
|---|---|
| ≥ 95 列 | 立体字样 ANSI Shadow(83 列) |
| 59 ~ 94 列 | 块体字样(51 列) |
| < 59 列 | 退回一行纯文字标题 |

菜单宽度跟着 header 走(header 的 50%~72%),让两者的宽度比例看起来是刻意
设计的。内容整体**垂直居中**,不会挤在顶部。窗口太矮时自动省略页脚,
而不是让它被挤出屏幕。调整窗口会即时重排。

### 改字样 / 调大小

文件顶部有两个开关:

```lua
local FORCE_HEADER = nil   -- 'shadow' | 'block' | 'text',nil = 按宽度自动
local ADAPTIVE = true      -- 关掉就固定块体、不垂直居中
```

两套字形表(`SHADOW_FONT` 立体、`BLOCK_FONT` 块体)都在
`lua/plugins/dashboard.lua` 顶部,每个字母定义若干行。改字样只需改
`WORD = 'SNAKENVIM'`;表里没有的字母会被跳过。

字形是手写的,所以渲染时会自动把每个字母各行补齐到等宽 ——
某行多打或少打一个空格不会让整幅画错位。

**注意 ANSI Shadow 不要放大**:`╔╗` 这类角字符一拉伸就散架(不像 `█` 可以
精确复制),所以它只用原始尺寸,靠全宽的装饰带把屏幕撑满。

字符用的是 `█ ═ ║` 这类通用符号而不是 Nerd Font 私有码点:
任何等宽字体都有这些字形,iPad 上走 mosh 也不会变成豆腐块。

---

## 主题

5 套深色主题,`<Space>ut` 打开选择器即可实时预览:

| 主题 | 风格 |
|---|---|
| **kanagawa**(默认) | 深墨底,蓝紫点缀 |
| oxocarbon | 近纯黑,极简克制 |
| catppuccin | 柔和低对比(mocha) |
| rose-pine | 优雅紫调 |
| carbonfox | 纯黑冷调 |

**换主题的方式不限**:选择器、手敲 `:colorscheme xxx` 都会被记住。
记录写在 `stdpath('state')` 里,所以**每台机器各记各的** ——
Windows 上选 kanagawa、iPad 上选 carbonfox 互不影响。

启动时只加载当前主题那一套,其余 4 套等你切换时才加载。

---

## 加一门语言

只需要改**一个地方**:`lua/config/langs.lua`。

```lua
{
  ft = 'rust',                        -- 文件类型(可以是数组)
  lsp = 'rust_analyzer',              -- LSP 服务器,由 mason 自动装
  parsers = { 'rust' },               -- 语法解析器,自动装
  formatter = 'rustfmt',              -- 格式化器,由 mason 自动装
  indent = 4,                         -- 缩进
},
```

LSP 安装清单、解析器清单、格式化器清单、缩进规则四件事都由这张表推导,
**不需要**再去改 `config/lsp.lua` 或 `plugins/coding.lua`。

只想高亮不要 LSP 也行,把 `lsp` 字段省掉即可(文件里已有汇编的例子)。

---

## 通过 mosh 从 iPad 使用

配置会自动检测 mosh / ssh 会话,并**只改变一件事**:

**剪贴板改走 OSC52。** 因为通过 mosh 操作 mac 上的 nvim 时,`y` 会把内容送进
**mac 的剪贴板**,而你眼前是 iPad —— 粘贴时什么都得不到。走 OSC52 则顺 mosh
通道把内容回传给 iPad 终端。

界面不做任何缩水:图标、主题、状态栏都和电脑上一致。

### 如果 iPad 上操作发涩

按 `<Space>uo` 打开 mosh 卡顿优化。它会关掉三个「光标一动就重绘」的东西:

- `cursorline` — 每次移动整行重绘
- `mini.indentscope` — 缩进指示线
- 调高 `updatetime` — 降低 CursorHold 类动作的触发频率

默认关闭,因为横屏 + 物理键盘下的体验和本机很接近,没必要默认牺牲这些。

### 如果 RootShell 字体不支持 Nerd Font

图标会显示成豆腐块。按 `<Space>ui` 切到 ASCII,选择会被记住。
(注意:这个开关要重启 nvim 才会完全生效,因为图标依赖的插件在启动时决定是否加载。)

### 如果 OSC52 不被 RootShell 支持

用 `<Space>yc` 直接把内容送进 mac 本机的剪贴板(`pbcopy`)。

### 手动模拟

```bash
NVIM_PROFILE=lite nvim   # 在完整终端里模拟远程环境
NVIM_PROFILE=full nvim   # 在 iPad 上强制走本机行为
```

---

## 维护

### 更新插件

```bash
nvim          # 然后 :Lazy update
```

> **Windows 注意**:更新前先关掉所有 nvim 实例。
> blink.cmp 的模糊匹配 DLL 在运行中被占用时,`:Lazy update` 可能报 `EPERM`。

更新后 `lazy-lock.json` 会变化,记得提交 —— 这份文件保证两台机器的插件版本一致。

### 在两台机器间同步

```bash
git pull      # 拉取另一台机器的改动
git push      # 推送本机的改动
```

配置目录就是 git 工作区,所以你可以**在 nvim 里直接改自己的配置**:
用 `<Space>fn` 打开配置文件编辑,gitsigns 会标出改动,直接 commit 即可,不用离开编辑器。

会出现冲突的通常只有 `lazy-lock.json`(两边都更新过插件时),手动解决即可。

---

## 目录结构

```
init.lua                    入口,只做 require
lua/config/
  profile.lua               ★ 平台 + 远程检测(整个配置只在这里判断平台)
  options.lua               编辑器选项
  keymaps.lua               通用键位
  autocmds.lua              自动命令
  langs.lua                 ★ 语言单一数据源(加语言改这里)
  lsp.lua                   由 langs 驱动的 LSP 配置
  theme.lua                 ★ 主题切换 + 记忆 + 图标开关
  lazy.lua                  lazy.nvim 自举
lua/plugins/                插件定义(按用途分组)
lua/snake/health.lua        :checkhealth snake 的实现
```

两个 `★` 标记的文件是核心抽象:平台/远程差异全部收敛进 `profile.lua`,
语言相关的四份清单全部由 `langs.lua` 推导 ——
所以插件文件里不会出现散落的平台判断或重复声明的语言清单。
