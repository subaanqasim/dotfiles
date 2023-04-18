return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        visible = true,
        hide_dotfiles = false,
        hide_gitignored = true,
      },
      bind_to_cwd = true,
      cwd_target = {
        sidebar = "global", -- sidebar is when position = left or right
        current = "none", -- current is when position = current
      },
    },
    window = {
      width = 30,
    },
  },
}
