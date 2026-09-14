-- snake's neovim
--
-- 入口只做 require,真正的逻辑都在 lua/config/ 下,方便单独定位和修改。
-- 加载顺序有讲究,不要随意调整,原因见每行注释。

vim.g.snake_nvim = true

require('config.profile') -- 纯探测,无副作用。必须最先,后面所有文件都读它
require('config.options') -- 选项必须在插件加载前设好,否则插件读到的是默认值
require('config.lazy')    -- lazy.nvim 自举并加载插件
require('config.theme').setup() -- 应用上次记住的主题(必要时按需加载对应的主题插件)
require('config.langs')   -- 语言单一数据源,推导出高亮/缩进/格式化清单
require('config.lsp')     -- 由 langs 驱动的 LSP 配置
require('config.keymaps')
require('config.autocmds')
