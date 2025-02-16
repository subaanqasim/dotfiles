return {
  "folke/snacks.nvim",
  ---@type snacks.Config
  opts = {
    dashboard = {
      preset = {
        header = [[




 ]],
      },
    },

    lazygit = {
      enabled = true,
    },
    ---@type snacks.picker.Config
    picker = {
      sources = {
        files = {
          hidden = true,
          -- follow = true,
        },
        grep = {
          hidden = true,
        },
        -- explorer = {
        --   hidden = true,
        --   ignored = true,
        --   -- follow = true,
        --   jump = { close = false },
        --   layout = {
        --     preset = "sidebar",
        --     preview = false,
        --   },
        -- },
      },
    },
  },
}
