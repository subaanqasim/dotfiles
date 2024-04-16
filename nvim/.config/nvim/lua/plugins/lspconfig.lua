local util = require("lspconfig.util")

local function get_typescript_server_path(root_dir)
  local project_root = util.find_node_modules_ancestor(root_dir)
  return project_root and (util.path.join(project_root, "node_modules", "typescript", "lib")) or ""
end

return {
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
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
