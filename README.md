# snakenvim

一套精简、可跨平台同步的 Neovim 配置。Windows 和 macOS 共用同一份仓库,
Win11 上用 Windows Terminal、macOS 上也可能被 iPad 通过 mosh 远程使用。

29 个插件(对比 LazyVim 的 60+),没有成品发行版那层 abstraction,
每个文件都能直接读懂、直接改。

---

## 安装

两个平台各自把仓库 clone 到**该平台的配置目录**,靠 git 同步:

**Windows**

```powershell
git clone https://github.com/sheshuyu/snakenvim.git "$env:LOCALAPPDATA\nvim"
```

**macOS**

```bash
git clone https://github.com/sheshuyu/snakenvim.git ~/.config/nvim
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
| **tree-sitter-cli** | 编译 cpp / python 语法解析器 | `scoop install tree-sitter` | `brew install tree-sitter-cli` |
| **C 编译器** | 同上 | 通常已有(gcc/clang) | Xcode 命令行工具 |
| ripgrep | 全文搜索 | `scoop install ripgrep` | `brew install ripgrep` |
| fd | 文件查找 | `scoop install fd` | `brew install fd` |
| yazi | 文件管理(`<Space>e`),也接管 `nvim <目录>` | `scoop install yazi` | `brew install yazi` |
| lazygit | 完整 git TUI(`<Space>gg`) | 先 `scoop bucket add extras`,再 `scoop install lazygit` | `brew install lazygit` |

**缺失不会导致 nvim 起不来。** 少了 `tree-sitter-cli` 时 cpp / python 会自动退回
内置的正则高亮并给出提示,C 和 Lua 用的是 nvim 自带解析器,不受影响。

> macOS 注意:Homebrew 的 `tree-sitter` 公式**只装 libtree-sitter 库,不带命令行工具**。
> 装完仍然会提示找不到 `tree-sitter` 就是这个原因 —— 要装的是 `tree-sitter-cli`
> (`brew uninstall tree-sitter` 可以顺手把那个用不上的库删掉)。

随时用 `:checkhealth snakenvim` 查看缺什么、怎么装,或 `:Snakenvim` 看一行行状态速查。

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
| `<C-\>` | **浮动终端**开关(高频操作所以给单键;终端里 `<C-q>` 一步收起) |
| `<Space>e` | **文件管理**:打开 yazi(起在当前文件所在目录) |
| `<Space>fn` | 新建文件 |
| `<Space>sn` | **编辑 nvim 配置** |

#### flash:屏幕内快速跳转

按 `s` 输入一两个字符,屏幕上所有匹配处会标上字母标签,按标签**直接跳过去**——
不用数行数、不用 `n`/`n`/`n` 一个个挪。

| 键位 | 作用 |
|---|---|
| `s` | 跳转(普通 / 可视 / 操作符模式都可用) |
| `S` | 按**语法节点**选中(treesitter) |
| `r`(操作符模式) | 跨窗口跳 |
| `R`(可视/操作符) | 语法节点搜索 |
| `<C-s>`(命令行) | 开关搜索模式 |
| `f` / `t` / `F` / `T` | 已增强:会高亮屏幕上所有同名字符并标标签,能跨行直接跳 |

用 `/` 搜索时也会启用标签,输入几个字符后直接按标签跳过去。

> ⚠️ **`s` 和 `S` 覆盖了 vim 自带的「替换字符」和「替换整行」。** 这是 flash 的
> 社区标准键位(LazyVim 也一样),但确实丢了这两个命令。想留住的话,把
> `lua/plugins/flash.lua` 里 keys 的 `'s'` / `'S'` 换成别的键即可。
>
> 连带影响:mini.surround 的前缀已从 `sa`/`sd`/`sr` 改成 **`gsa`/`gsd`/`gsr`**。
> 不改的话按 `s` 之后 vim 要等 400ms 才能分辨你要 flash 还是要 surround,每次都会卡。

#### 浮动终端

自己实现的(见 `lua/config/terminal.lua`),不装插件。取窗口的 80%×60% 居中,
圆角边框。**收起时只是隐藏窗口、不杀进程** —— 下次 `<C-\>` 打开还是同一个
会话,里面跑的东西都还在。

> **为什么是 `<C-\>` 而不是 `<Space>tt`**:开终端是高频操作,三个键太啰嗦。
> 但**不能改成 `<Space>t`** —— 那会让它变成映射前缀,每次按 `<Space>t` 都要等
> timeoutlen(400ms)才能确定你是要开终端、还是要按 `<Space>tT`,和上面
> flash / surround 抢 `s` 是同一类问题。
> `<C-\>` 不占任何字母、不当前缀、各键盘布局位置一致。它只绑在**普通模式**;
> 终端模式里 `<C-\><C-n>` 是 vim 内建的「回到普通模式」,那一串不能被抢走。

收起浮窗有三条路:终端里直接按 **`<C-q>`**(一步最快)、`<Esc><Esc>` 回普通模式
再按 `q`(和 help / quickfix 窗口的习惯一致)、或再按一次 `<C-\>`。
选 `<C-q>` 是因为它原本是终端的 XON 流控,日常用不到。
于是开和收正好配成一对:**`<C-\>` 开(普通模式),`<C-q>` 收(终端模式)**。

**终端开在当前文件所在目录**,所以打开 `main.c` 后按 `<C-\>` 就能直接:

```bash
gcc main.c -o main && ./main
```

不用先 `cd` 过去。

复用已有会话时目录**不会**自动跟着当前文件走 —— 这是故意的:往终端里发 `cd`
有风险,如果 shell 里正有个程序在等输入,那串字符会被它当成输入吃掉。
目录不一致时会提示一句,想换目录按 `<Space>tT` 在新目录重开。

#### 文件管理:yazi

`<Space>e` 打开 **yazi**,起点是**当前文件所在目录**。yazi 本身是独立的 TUI 文件
管理器(`lua/plugins/explorer.lua` 只是把它接进 nvim),浏览、移动、改名、批量
操作都在它自己窗口里完成。

原来这里是 nvim-tree + oil 两个插件,职责重叠,已合并成这一个入口。
**功能对等,但形态不等价** —— 三点差异要清楚:

| 原键位 | 原来 | 现在 |
|---|---|---|
| `<Space>e` | nvim-tree:固定 32 列常驻侧边栏 | yazi:独立窗口,不常驻、也不占编辑区 |
| `-` | oil:把目录当缓冲区,用 `:%s/`、`dd` 改路径 | **已释放**,回到 vim 内建的「行首上移」 |
| `<Space>E` | nvim-tree:在树里定位当前文件 | **已删除** —— yazi 不是树,没有对等物 |

**`nvim <目录>` 现在直接开 yazi**(取代 netrw),所以 `nvim .` 就能浏览当前目录。

> **只在 yazi 装了的时候才接管。** 没装 yazi 时 netrw 会被保留,目录照常能浏览
> (`<Space>e` 也会退回内置浏览器并提示怎么装)。
> 这个判断是必须的:yazi 接管目录的方式是**把 netrw 关掉**,如果 yazi 又不在,
> 结果就是 `nvim <目录>` 只得到一个空缓冲区、连目录都打不开 —— mac 上装了、
> Windows 上没装时就会撞上。
这条靠 `open_for_directories`;实现细节、以及「为什么它的懒加载不能用 `cmd` 而
必须用 `event`」写在 `lua/plugins/explorer.lua` 顶部注释里。

**退出 yazi 按 `q`**(yazi 自己的键,按完干净退回原文件)。`<Space>e` 只负责
打开、**不做切换** —— 理由写在 `explorer.lua` 注释里:yazi 里 `<Space>` 是
「选中文件」,把它变成映射前缀会让每次选文件都等 400ms。

> yazi 的**文件图标和图片预览需要 Nerd Font**。没有 Nerd Font 的终端(iPad
> RootShell 就是)基本操作不受影响,只是图标位置缺字形。

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
| `<Space>lD` / `<Space>lR` | 定义 / 引用列表(先列候选再挑,同名符号多时好用) |
| `<Space>lI` / `<Space>lT` | 实现 / 类型定义列表 |
| `<Space>lv` | 竖分屏打开定义(不丢掉当前位置) |
| `<C-o>` / `<C-i>` | 跳回上一个位置 / 前进(vim 自带跳转栈) |
| `K` | 悬停文档 |

> **三种「跳转」的分工**:`s`(flash)是**当前屏幕内**跳到任意位置;`gd`/`gr` 是
> **跨文件按语义**跳;`<Space>lD` 系列是 LSP 的**候选列表**,同名符号多时挑着跳。
| `<Space>cr` / `<Space>lr` | 重命名符号(前者是 LazyVim 习惯) |
| `<Space>ca` / `<Space>la` | 代码操作(自动导入、快速修复) |
| `<Space>cl` | 查看 LSP 客户端状态 |
| `]c` / `[c` | 上/下一个 Git 改动块 |
| `<Space>gg` | **lazygit**:完整 git TUI(提交 / 分支 / rebase);没装 lazygit 时退回终端 `git` |

### 界面(`<Space>u`)

| 键位 | 作用 |
|---|---|
| `<Space>ut` | **切换主题**(带实时预览,选择会被记住) |
| `<Space>ui` | 图标 / ASCII 切换 |
| `<Space>uo` | 远程卡顿优化开关 |

#### 几个纯视觉增强

都是在新加插件时一起做的,不需要按键:

- **彩虹缩进线**(indent-blankline)—— 每层缩进不同颜色,色板取自 One Dark
- **彩虹括号**(rainbow-delimiters)—— 嵌套的括号/引号按层级变色
- **代码上下文头**(treesitter-context)—— 顶部吸附显示当前所在的函数/类签名
- **markdown 渲染**(render-markdown)—— 标题加粗、表格对齐、代码块加底色、
  `- [ ]` 变复选框。**在缓冲区里直接画**,不弹浏览器/不依赖外部程序,
  所以在 iPad 的 ssh 里照常工作

> **状态栏与 markdown 渲染里的图标都是特意关掉的。** lualine 的 filetype /
> branch / diff 组件默认会画 Nerd Font 私有区字形(py 是 U+E606、md 是 U+F48A),
> markdown 渲染的标题/复选框/代码块图标同样是私有区。没有 Nerd Font 的终端上
> 这些全是豆腐块,所以统一关掉、改用文字和通用符号 —— 和下面的缩进线是同一套原则。
- **浮动通知**(mini.notify)—— 所有提示变成右上角浮窗。**这改变了全部消息的
  显示方式**:以前多行消息会顶出「Press ENTER or type command to continue」,
  现在浮窗放得下,不再打断你;`:Snakenvim` 的整份状态摘要也能完整显示

> 缩进线用的是 `│`(U+2502,方块绘制字符),不用 Nerd Font 私有区 ——
> 和状态栏、诊断图标是同一套「不依赖 Nerd Font」的思路。

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


                        snakenvim
                        按 <Space> 查看所有键位
```

| 键 | 作用 |
|---|---|
| `n` | 新建文件(输入路径) |
| `f` | 查找文件 |
| `r` | 最近打开的文件 |
| `c` | 打开配置目录(用 yazi,可直接编辑) |
| `q` | 退出 |

把光标移到某一行按回车也可以。这些快捷键**只在该界面内生效**,不会污染其它缓冲区。

### 视觉效果

- **立体字样**用 ANSI Shadow: `█` 做填充,`╔╗╚╝═║` 做棱边和投影,
  立体感来自字形本身而不是特效
- **颜色是渐变**:header 自上而下由亮到暗(模拟顶部打光),端点颜色从当前
  配色方案里取(实测 kanagawa 出蓝、oxocarbon 出灰白),换主题会自动跟着变
- **菜单用引导线拉满**:每行做成 `▸ 标签 ┈┈┈┈ 快捷键` 的完整条目,
  而不是几根飘在巨大 header 下面的小字 —— 菜单整体成为一个有分量的块
- **选中条只框住菜单那一块**(不是整行铺满),像 fzf 的选中行

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
精确复制),所以它只用原始尺寸。

字符用的是 `█ ═ ║` 这类通用符号而不是 Nerd Font 私有码点:
任何等宽字体都有这些字形,iPad 上走 mosh 也不会变成豆腐块。

---

## 主题

5 套深色主题,`<Space>ut` 打开选择器即可实时预览:

| 主题 | 底色 | 风格 |
|---|---|---|
| **oxocarbon**(默认) | `#161616` 中性黑 | 单色极简,连强调色都不带蓝 |
| carbonfox | `#161616` 中性黑 | 纯黑冷调,但强调色是蓝的 |
| kanagawa | `#1f1f28` 偏蓝 | 深墨底,蓝紫点缀 |
| catppuccin | `#1a1b1d` 中性黑 | **Trae 配色**:近黑底 + 柔和粉彩 |
| rose-pine | `#191724` 偏蓝 | 优雅紫调 |

默认选 oxocarbon 的原因:只有它的底色是**真正中性**的(R=G=B=22),
而且它是单色主题、强调色也不带蓝。其余几套的底色都偏蓝(B 通道比 R/G 高)。

> **catppuccin 那一项被调成了 Trae 的配色。** 色值不是猜的,是从本机 Trae CN 的
> `globalStorage/state.vscdb` 里读出来的:它的主题其实是 `icube-themes` 扩展的
> `themes/dark_plus.json`,但调色板是 icube 自己调过的 —— 底色 `#1a1b1d`
> (中性灰,不偏蓝),蓝色 `#80BBFF`、绿色 `#82D99F`、紫色 `#B38CFF`。
> 换句话说:**它不是 One Dark**(One Dark 的底色 `#282c34` 明显偏蓝)。
> 实现方式是 catppuccin 的 `color_overrides`(见 `plugins/colorschemes.lua`),
> 前 15 个槽位直接取自 Trae,所以零新增依赖。

> 换主题的方式:改 `lua/config/theme.lua` 里的 `M.default_theme`,
> **并且**清掉 `stdpath('state')/snakenvim.json` 里记住的 `theme` ——
> 那个记录会覆盖默认值,只改默认是不生效的。

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

## 自己加插件 / 改配置

### 插件文件放哪

`lua/plugins/` 下**一个文件一个主题域**,不是按插件数量分:

| 文件 | 管什么 |
|---|---|
| `coding.lua` | 补全 / LSP / 格式化(清单全部从 `config/langs.lua` 推导) |
| `editor.lua` | 语法高亮与编辑增强(treesitter、彩虹括号、markdown 渲染、mini.nvim) |
| `ui.lua` | 纯视觉(状态栏、彩虹缩进线、键位提示) |
| `explorer.lua` | 文件管理(yazi) |
| `find.lua` / `flash.lua` / `git.lua` / `dashboard.lua` / `colorschemes.lua` | 各管一摊 |

加之前先想清楚**它属于哪个域**,放进对应文件;确实都不属于,再新开一个。
每个文件顶部都要写清「**为什么选它 / 有什么坑**」—— 这是这份配置最重要的约定,
比代码本身值钱。

### 最小模板

```lua
{
  '作者/仓库名',
  event = 'VeryLazy',          -- 何时加载,见下
  keys = {
    { '<leader>xx', '<cmd>某命令<CR>', desc = '一句话说明' },
  },
  opts = { ... },              -- 传给插件的 setup() 参数
},
```

### 懒加载怎么选(这是最容易踩坑的地方)

| 写法 | 什么时候加载 | 适合 |
|---|---|---|
| `lazy = false` | 启动时 | 主题、treesitter 这类必须早的 |
| `event = 'VeryLazy'` | 启动稍后 | 大多数插件(状态栏、键位提示) |
| `event = { 'BufReadPre', 'BufNewFile' }` | 打开文件时 | 缩进线、语法相关 |
| `ft = { 'markdown' }` | 进入该文件类型时 | 语言专属插件 |
| `cmd = '某命令'` | 敲到该命令时 | 偶尔用的工具 |

> ⚠️ **别用 `cmd` 懒加载需要「启动后立刻生效」的插件。** 踩过的例子:
> yazi.nvim 要接管 `nvim <目录>`,靠的是 `setup()` 里注册的 autocmd ——
> 用 `cmd` 的话那个目录永远等不到它。详见 `plugins/explorer.lua` 顶部。

### 键位写在哪

**插件专属键位写在插件自己的 `keys` 字段里**,不要放 `config/keymaps.lua` ——
那个文件只放与插件无关的通用键位。这是明文约定。

加键位前先想两件事:
1. **会不会抢拼音前缀?** 比如把两个功能都绑到 `<Space>e`,按第二次就退不回去。
2. **会不会变成前缀导致延迟?** 一旦某个键成了别的映射的前缀,单独按它就得等
   `timeoutlen`(400ms)。这就是 `s`(flash vs surround)、`<Space>t`
   (终端 vs 重开)都被特意避开的原因。

### 改完怎么验证

```bash
# 1. 启动有没有报错(最重要,一条命令)
nvim --headless -c 'lua vim.defer_fn(function() vim.cmd("qa!") end, 8000)'

# 2. 插件状态、有没有缺依赖
#    在 nvim 里::Lazy   /   :checkhealth snakenvim
```

新插件装好后记得把 `lazy-lock.json` 一起提交,两台机器的版本才会一致。

### ⛔ 装插件前:github.com 需要代理

这台 Mac 上 **github.com 的 HTTPS 是被挡的**(实测 443 超时),而
`api.github.com` / `raw.githubusercontent.com` 通。所以 lazy 装插件、以及
`git fetch/push` 都得走本地代理(Clash Verge 的 mixed 端口是 **7897**):

```bash
# lazy 装/更新插件(给 nvim 进程带上代理环境变量)
https_proxy=http://127.0.0.1:7897 http_proxy=http://127.0.0.1:7897 nvim

# git 操作
git -c http.proxy=http://127.0.0.1:7897 fetch
```

前提是 **Clash Verge 得先开着**(它默认不开机自启,`enable_auto_launch: false`)。
确认端口在监听:`nc -z 127.0.0.1 7897 && echo ok`

---

## 通过 mosh 从 iPad 使用

配置会自动检测 mosh / ssh 会话,并**只改变一件事**:

**剪贴板改走 OSC52。** 因为通过 SSH / mosh 操作 mac 上的 nvim 时,`y` 会把内容送进
**mac 的剪贴板**,而你眼前是 iPad —— 粘贴时什么都得不到。走 OSC52 则顺 mosh
通道把内容回传给 iPad 终端。

界面不做任何缩水:图标、主题、状态栏都和电脑上一致。

### 如果 iPad 上操作发涩

按 `<Space>uo` 打开 远程卡顿优化。它会关掉这几个「光标一动就重绘」的东西:

- `cursorline` — 每次移动整行重绘
- **缩进线**(indent-blankline)— 每次移动重绘缩进指示线
- **代码上下文头**(treesitter-context)— 它按光标位置重算当前函数/类
- 调高 `updatetime` — 降低 CursorHold 类动作的触发频率

默认关闭,因为横屏 + 物理键盘下的体验和本机很接近,没必要默认牺牲这些。

> 彩虹括号**不在**这个开关里。它的开销是按缓冲区变化触发的,不属于「光标一动就
> 重绘」那一类,而且它只有按缓冲区的 API、没有全局开关。这是刻意的,不是漏做。

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
lua/snakenvim/health.lua        :checkhealth snakenvim 的实现
```

两个 `★` 标记的文件是核心抽象:平台/远程差异全部收敛进 `profile.lua`,
语言相关的四份清单全部由 `langs.lua` 推导 ——
所以插件文件里不会出现散落的平台判断或重复声明的语言清单。
