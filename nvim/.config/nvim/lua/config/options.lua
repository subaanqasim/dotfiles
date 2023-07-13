-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.winbar = "%=%m %f"
vim.g.material_style = "darker"

local opt = vim.opt

opt.wrap = true
opt.conceallevel = 0

vim.filetype.add({
  extension = {
    astro = "astro",
  },
})
