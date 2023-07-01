return {
  {
    "ahmedkhalf/project.nvim",
    opts = {
      manual_mode = false,
      silent_chdir = true,
      detection_methods = { "pattern", "lsp" },
      patterns = { ".git", "*-lock.json" },
      exclude_dirs = { "node_modules" },
    },
  },
}
