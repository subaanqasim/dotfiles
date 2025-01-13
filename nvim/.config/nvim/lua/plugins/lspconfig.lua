local lspconfig = require("lspconfig")
return {
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      inlay_hints = { enabled = false },
      document_highlight = {
        enabled = false,
      },
      servers = {
        prismals = {},
        tailwindcss = {
          settings = {
            tailwindCSS = {
              experimental = {
                classRegex = {
                  { "cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
                  { "cn\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)" },
                  { "cx\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)" },
                  { "tv\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)" },
                  { "clsx\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)" },
                },
              },
            },
          },
        },
        bufls = {},
        -- eslint = {
        --   settings = {
        --     workingDirectory = { mode = "location" },
        --   },
        --   root_dir = lspconfig.util.find_git_ancestor,
        -- },
        gh_actions_ls = {},
      },
      setup = {
        eslint = function() end, -- disable autofix on save by LazyVim
      },
    },
  },
}
