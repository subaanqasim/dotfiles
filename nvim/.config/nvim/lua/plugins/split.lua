return {
  "mrjones2014/smart-splits.nvim",
  lazy = false,
  keys = {
    -- moving between splits
    {
      "<C-h>",
      function()
        require("smart-splits").move_cursor_left()
      end,
    },
    {
      "<C-j>",
      function()
        require("smart-splits").move_cursor_down()
      end,
    },
    {
      "<C-k>",
      function()
        require("smart-splits").move_cursor_up()
      end,
    },
    {
      "<C-l>",
      function()
        require("smart-splits").move_cursor_right()
      end,
    },
    {
      "<C-\\>",
      function()
        require("smart-splits").move_cursor_previous()
      end,
    },
    -- resizing splits
    -- these keymaps will also accept a range,
    -- for example `10<A-h>` will `resize_left` by `(10 * config.default_amount)`
    -- {
    --   "<C-Left>",
    --   require("smart-splits").resize_left,
    -- },
    -- { "<C-Down>", require("smart-splits").resize_down },
    -- { "<C-Up>", require("smart-splits").resize_up },
    -- { "<C-Right>", require("smart-splits").resize_right },
  },
}
