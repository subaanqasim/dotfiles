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
        gh_actions_ls = {},
        eslint = {
          settings = {
            workingDirectories = {
              mode = "location",
            },
            -- root_dir = lspconfig.util.root_pattern(".git", "package.json", "tsconfig.json"),
            flags = {
              allow_incremental_sync = false,
              debounce_text_changes = 1000,
            },
            -- flags = os.getenv("DEBOUNCE_ESLINT") and {
            --   allow_incremental_sync = false,
            --   debounce_text_changes = 1000,
            -- } or nil,
          },
        },
      },
    },
  },
}
