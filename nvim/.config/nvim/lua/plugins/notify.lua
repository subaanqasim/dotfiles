return {
  {
    "rcarriga/nvim-notify",
    opts = function()
      require("notify").setup({
        background_colour = "#000000",
      })
    end,
  },
}
