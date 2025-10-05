return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- disable copilot to prevent license key error on startup
        -- copilot is only required for NES, so re-enable if required
        copilot = { enabled = false },
      },
    },
  },
  {
    "folke/sidekick.nvim",
    opts = {
      nes = { enabled = false },
    },
  },
}
