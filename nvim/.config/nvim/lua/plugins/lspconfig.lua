return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        astro = {},
        prismals = {},
        tailwindcss = {},
        tsserver = {
          root_dir = require("lspconfig/util").root_pattern(
            ".git",
            "package-lock.json",
            "tsconfig.json",
            "package.json"
          ),
        },
      },
    },
  },
}
