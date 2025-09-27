return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "prettierd",
        "eslint_d",
        "biome",
        "typescript-language-server",
        "lua-language-server",
        "css-lsp",
        "html-lsp",
        "js-debug-adapter",
        "stylua",
        "tailwindcss-language-server",
        "astro-language-server",
        "json-lsp",
        "shfmt",
        "prisma-language-server",
        "rust-analyzer",
        "buf-language-server",
      })
    end,
  },
}
