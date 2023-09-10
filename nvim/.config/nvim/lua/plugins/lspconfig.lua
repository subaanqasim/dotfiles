local util = require("lspconfig.util")

local function get_typescript_server_path(root_dir)
  local project_root = util.find_node_modules_ancestor(root_dir)
  return project_root and (util.path.join(project_root, "node_modules", "typescript", "lib")) or ""
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        astro = {},
        -- astro = {
        --   cmd = { "astro-ls", "--stdio" },
        --   filetypes = {
        --     "astro",
        --     "javascript",
        --     "javascriptreact",
        --     "javascript.jsx",
        --     "typescript",
        --     "typescriptreact",
        --     "typescript.tsx",
        --   },
        --   root_dir = util.root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git"),
        --   init_options = {
        --     typescript = {},
        --   },
        --   on_new_config = function(new_config, new_root_dir)
        --     if vim.tbl_get(new_config.init_options, "typescript") and not new_config.init_options.typescript.tsdk then
        --       new_config.init_options.typescript.tsdk = get_typescript_server_path(new_root_dir)
        --     end
        --   end,
        -- },
        volar = {},
        prismals = {},
        tailwindcss = {},
        bufls = {},
      },
      setup = {
        eslint = function() end, -- disable autofix on save by LazyVim
      },
    },
  },
}
