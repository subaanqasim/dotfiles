return {
  "nvimdev/dashboard-nvim",
  opts = function(_, opts)
    local placeholder = [[











    ]]

    opts.config.header = vim.split(placeholder, "\n")
  end,
}
