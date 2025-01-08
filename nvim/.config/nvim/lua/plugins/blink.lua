return {
  {
    "saghen/blink.cmp",
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      completion = {
        list = {
          selection = { preselect = true, auto_insert = true },
        },
        menu = {
          border = "rounded",
        },
        documentation = {
          window = {
            border = "rounded",
          },
        },
      },
      signature = { window = { border = "rounded" } },
    },
  },
}
