return {
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      local function border(hl_name)
        return {
          { "╭", hl_name },
          { "─", hl_name },
          { "╮", hl_name },
          { "│", hl_name },
          { "╯", hl_name },
          { "─", hl_name },
          { "╰", hl_name },
          { "│", hl_name },
        }
      end

      opts.window = {
        completion = {
          border = border("CmpBorder"),
        },
        documentation = {
          border = border("CmpDocBorder"),
        },
      }
    end,
  },
}
