return {
  {
    "olivercederborg/poimandres.nvim",
    lazy = true,
    -- priority = 1000,
    opts = {
      bold_vert_split = true, -- use bold vertical separators
      dim_nc_background = true, -- dim 'non-current' window backgrounds
      disable_background = false, -- disable background
      disable_float_background = false, -- disable background for floats
      disable_italics = false, -- disable italics
    },
  },

  {
    "marko-cerovac/material.nvim",
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    dependencies = { "nvim-lualine/lualine.nvim" },

    opts = {
      contrast = {
        terminal = false, -- Enable contrast for the built-in terminal
        sidebars = true, -- Enable contrast for sidebar-like windows ( for example Nvim-Tree )
        floating_windows = true, -- Enable contrast for floating windows
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

      plugins = { -- Uncomment the plugins that you use to highlight them
        -- Available plugins:
        "dap",
        "dashboard",
        "gitsigns",
        -- "hop",
        -- "indent-blankline",
        -- "lspsaga",
        "mini",
        -- "neogit",
        -- "neorg",
        "nvim-cmp",
        "nvim-navic",
        "nvim-tree",
        "nvim-web-devicons",
        -- "sneak",
        "telescope",
        "trouble",
        "which-key",
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
    "catppuccin/nvim",
    lazy = false,
    -- priority = 1000,
    name = "catppuccin",
    opts = {
      flavour = "mocha", -- latte, frappe, macchiato, mocha
      background = { -- :h background
        light = "latte",
        dark = "mocha",
      },
      transparent_background = false,
      show_end_of_buffer = false, -- show the '~' characters after the end of buffers
      dim_inactive = {
        enabled = true,
        shade = "dark",
        percentage = 0.2,
      },
      no_italic = false, -- Force no italic
      no_bold = false, -- Force no bold
      styles = {
        comments = { "italic" },
        conditionals = { "italic" },
        functions = { "bold" },
      },
    },
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "material",
    },
  },
}
