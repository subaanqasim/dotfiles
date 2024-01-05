return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {},
  init = function()
    local harpoon = require("harpoon")
    -- REQUIRED
    harpoon:setup()
    -- REQUIRED
  end,

  keys = function()
    return {
      {
        "<leader>a",
        function()
          require("harpoon"):list():append()
        end,
        desc = "Append file to harpoon",
      },
      {
        "<leader>h",
        function()
          local harpoon = require("harpoon")
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end,
        desc = "Toggle harpoon menu",
      },
      {
        "<C-m>",
        function()
          require("harpoon"):list():next()
        end,
        desc = "Next harpoon file",
      },
      {
        "<C-n>",
        function()
          require("harpoon"):list():prev()
        end,
        desc = "Previous harpoon file",
      },

      {
        "<leader>1",
        function()
          require("harpoon"):list():select(1)
        end,
        desc = "Select first harpoon file",
      },
      {
        "<leader>2",
        function()
          require("harpoon"):list():select(2)
        end,
        desc = "Select second harpoon file",
      },
      {
        "<leader>3",
        function()
          require("harpoon"):list():select(3)
        end,
        desc = "Select third harpoon file",
      },
      {
        "<leader>4",
        function()
          require("harpoon"):list():select(4)
        end,
        desc = "Select fourth harpoon file",
      },
    }
  end,
}
