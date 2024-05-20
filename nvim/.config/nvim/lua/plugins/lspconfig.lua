return {
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      inlay_hints = { enabled = false },
      servers = {
        astro = {},
        volar = {},
        prismals = {},
        tailwindcss = {
          -- settings = {
          --   tailwindCSS = {
          --     experimental = {
          --       classRegex = {
          --         { "cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
          --         { "cn\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)" },
          --         { "cx\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)" },
          --       },
          --     },
          --   },
          -- },
        },
        bufls = {},
      },
      setup = {
        eslint = function() end, -- disable autofix on save by LazyVim
      },
    },
  },
}
