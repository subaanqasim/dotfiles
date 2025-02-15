-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.snacks_animate = false

vim.lsp.set_log_level("off")
-- vim.lsp.set_log_level("debug")

vim.g.lazyvim_eslint_auto_format = false

-- vim.opt.winbar = "%=%m %f"
vim.g.material_style = "darker"

-- LazyVim root dir detection
-- Each entry can be:
-- * the name of a detector function like `lsp` or `cwd`
-- * a pattern or array of patterns like `.git` or `lua`.
-- * a function with signature `function(buf) -> string|string[]`
vim.g.root_spec = { { ".git" }, "lsp", "cwd" }

local opt = vim.opt

opt.wrap = true
opt.conceallevel = 0

-- vim.g.lazyvim_python_lsp = "pyright"
-- vim.g.lazyvim_python_ruff = "ruff_lsp"

-- adds yaml.github filetype for gh-actions-language-server
vim.filetype.add({
  pattern = {
    [".*/%.github[%w/]+workflows[%w/]+.*%.ya?ml"] = "yaml.github",
  },
})
