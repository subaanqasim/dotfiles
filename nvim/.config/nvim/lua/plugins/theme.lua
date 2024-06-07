return {
  {
    "marko-cerovac/material.nvim",
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    dependencies = { "nvim-lualine/lualine.nvim", "f-person/auto-dark-mode.nvim" },

    opts = {
      contrast = {
        terminal = false, -- Enable contrast for the built-in terminal
        sidebars = false, -- Enable contrast for sidebar-like windows ( for example Nvim-Tree )
        floating_windows = false, -- Enable contrast for floating windows
        cursor_line = false, -- Enable darker background for the cursor line
        non_current_windows = true, -- Enable darker background for non-current windows
        filetypes = {}, -- Specify which filetypes get the contrasted (darker) background
      },

      styles = {
        comments = { italic = true },
        functions = { bold = true },
        strings = {},
        keywords = {},
        variables = {},
        operators = {},
        types = {},
      },

      plugins = {
        -- "coc",
        -- "colorful-winsep",
        "dap",
        "dashboard",
        -- "eyeliner",
        -- "fidget",
        "flash",
        "gitsigns",
        "harpoon",
        -- "hop",
        -- "illuminate",
        -- "indent-blankline",
        -- "lspsaga",
        "mini",
        -- "neogit",
        "neotest",
        "neo-tree",
        -- "neorg",
        "noice",
        "nvim-cmp",
        "nvim-navic",
        -- "nvim-tree",
        "nvim-web-devicons",
        -- "rainbow-delimiters",
        -- "sneak",
        "telescope",
        "trouble",
        "which-key",
        -- "nvim-notify",
      },
      disable = {
        colored_cursor = false, -- Disable the colored cursor
        borders = false, -- Disable borders between verticaly split windows
        background = false, -- Prevent the theme from setting the background (NeoVim then uses your terminal background)
        term_colors = false, -- Prevent the theme from setting terminal colors
        eob_lines = false, -- Hide the end-of-buffer lines
      },

      high_visibility = {
        lighter = false, -- Enable higher contrast text for lighter style
        darker = false, -- Enable higher contrast text for darker style
      },

      lualine_style = "stealth", -- Lualine style ( can be 'stealth' or 'default' )

      async_loading = true, -- Load parts of the theme asyncronously for faster startup (turned on by default)
    },
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "material",
    },
  },

  {
    "f-person/auto-dark-mode.nvim",
    config = {
      update_interval = 1000,
      set_dark_mode = function()
        vim.api.nvim_set_option_value("background", "dark", { scope = "global" })
        require("material.functions").change_style("darker")
      end,
      set_light_mode = function()
        vim.api.nvim_set_option_value("background", "light", { scope = "global" })
        require("material.functions").change_style("lighter")
      end,
    },
  },
}
