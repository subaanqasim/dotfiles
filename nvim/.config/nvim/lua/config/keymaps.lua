-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local function map(mode, lhs, rhs, opts)
  local keys = require("lazy.core.handler").handlers.keys
  ---@cast keys LazyKeysHandler
  -- do not create the keymap if a lazy keys handler exists
  if not keys.active[keys.parse({ lhs, mode = mode }).id] then
    opts = opts or {}
    opts.silent = opts.silent ~= false
    vim.keymap.set(mode, lhs, rhs, opts)
  end
end

-- map("n", "<leader>sx", require("telescope.builtin").resume, { noremap = true, silent = true, desc = "Resume search" })
-- map("n", "<leader>zz", require("zen-mode").toggle, { noremap = true, desc = "Zen mode" })

-- quicker to enter normal mode
map("i", "jj", "<esc>", { noremap = true, silent = true })
map("i", "kj", "<esc>", { noremap = true, silent = true })
map("i", "kk", "<esc>", { noremap = true, silent = true })

-- keep cursor in same position when prepending line below
map("n", "J", "mzJ`z")

-- move cursor to center when navigating up/down and next/prev
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "<C-o>", "<C-o>zz")
map("n", "<C-i>", "<C-i>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- paste highlighted text without overwriting previously copied text
vim.keymap.set("x", "<leader>p", [["_dP]])

-- yank into system register (allows pasting outside of vim) - credit: asbjornHaland
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

-- map option+backspace to delete to beginning of word
map("i", "<A-BS>", "<C-w>")

-- map undo and redo
map("n", "<C-z>", "u", { noremap = true })
map("n", "<C-y>", "<C-r>", { noremap = true })
map("i", "<C-z>", "<C-o>u", { noremap = true })
map("i", "<C-y>", "<C-o><C-r>", { noremap = true })

-- more ergonomic tab switching
map("n", "<leader><tab>n", ":tabnext<CR>", { noremap = true, desc = "Next tab" })
map("n", "<leader><tab>p", ":tabprevious<CR>", { noremap = true, desc = "Previous tab" })
