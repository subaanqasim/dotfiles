return {
  {
    "polarmutex/git-worktree.nvim",
    version = "^2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").load_extension("git_worktree")
    end,
    keys = {
      { "<leader>gw", "<CMD>lua require('telescope').extensions.git_worktree.git_worktree()<CR>", desc = "Worktrees" },
      {
        "<leader>gW",
        "<CMD>lua require('telescope').extensions.git_worktree.create_git_worktree()<CR>",
        desc = "New worktree",
      },
    },
  },
  -- {
  --   "nvim-telescope/telescope.nvim",
  --   dependencies = {
  --     "polarmutex/git-worktree.nvim",
  --     config = function()
  --       require("telescope").load_extension("git_worktree")
  --     end,
  --   },
  --   keys = {
  --     { "<leader>gw", "<CMD>lua require('telescope').extensions.git_worktree.git_worktrees()<CR>", desc = "Worktrees" },
  --     {
  --       "<leader>gW",
  --       "<CMD>lua require('telescope').extensions.git_worktree.create_git_worktree()<CR>",
  --       desc = "New worktree",
  --     },
  --   },
  -- },
}
