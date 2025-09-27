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
        biome = {},
        prismals = {},
        tailwindcss = {
          -- settings = {
          -- flags = {
          --   -- allow_incremental_sync = false,
          --   debounce_text_changes = 1000,
          -- },
          -- },
        },
        bufls = {},
        gh_actions_ls = {},
        eslint = {
          -- cmd = { "eslint_d", "start", "--stdio" },
          settings = {
            workingDirectories = {
              -- mode = "location",
              mode = "auto",
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

      setup = {
        tailwindcss = function(_, opts)
          -- local tw = LazyVim.lsp.get_raw_config("tailwindcss")
          -- opts.filetypes = opts.filetypes or {}
          --
          -- -- Add default filetypes
          -- vim.list_extend(opts.filetypes, tw.default_config.filetypes)
          --
          -- -- Remove excluded filetypes
          -- --- @param ft string
          -- opts.filetypes = vim.tbl_filter(function(ft)
          --   return not vim.tbl_contains(opts.filetypes_exclude or {}, ft)
          -- end, opts.filetypes)

          opts.settings = {
            tailwindCSS = {
              classFunctions = {
                "tw",
                "tv",
                "cn",
                "cx",
                "clsx",
                "cva",
              },
              -- experimental = {
              --   classRegex = {
              --     { "cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
              --     { "cn\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)" },
              --     { "cx\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)" },
              --     { "clsx\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)" },
              --     { "tv\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)" },
              --     { "([\"'`][^\"'`]*.*?[\"'`])", "[\"'`]([^\"'`]*).*?[\"'`]" },
              --   },
              -- },
            },
          }

          -- Add additional filetypes
          -- vim.list_extend(opts.filetypes, opts.filetypes_include or {})
        end,
      },
    },
  },
}
