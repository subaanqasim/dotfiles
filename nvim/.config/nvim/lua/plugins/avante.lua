return {
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    opts = {
      ---@alias AvanteProvider "claude" | "openai" | "azure" | "gemini" | "cohere" | "copilot" | string
      -- provider = "claude", -- Recommend using Claude
      provider = "gemini",
      auto_suggestions_provider = "gemini",
      -- auto_suggestions_provider = "claude", -- Since auto-suggestions are a high-frequency operation and therefore expensive, it is recommended to specify an inexpensive provider or even a free provider: copilot
      claude = {
        endpoint = "https://api.anthropic.com",
        model = "claude-3-5-sonnet-20241022",
        -- model = "claude-3-7-sonnet-20250219",
        temperature = 0,
        max_completion_tokens = 8192,
      },

      gemini = {
        model = "gemini-2.5-pro-preview-03-25",
      },

      behaviour = {
        enable_cursor_planning_mode = true,
        -- enable_claude_text_editor_tool_mode = true,
        enable_token_counting = true,
        minimize_diff = true,
      },

      cursor_applying_provider = "groq",

      vendors = {
        groq = {
          __inherited_from = "openai",
          api_key_name = "GROQ_API_KEY",
          endpoint = "https://api.groq.com/openai/v1/",
          -- model = "qwen-2.5-coder-32b",
          model = "llama-3.3-70b-versatile",
          max_completion_tokens = 32768, -- 8192,
        },
      },

      web_search_engine = {
        provider = "tavily",
      },

      hints = { enabled = true },

      -- behaviour = {
      --   auto_suggestions = true, -- Experimental stage
      -- },
      -- suggestion = {
      --   debounce = 600,
      --   throttle = 600,
      -- },

      -- File selector configuration
      --- @alias FileSelectorProvider "native" | "fzf" | "mini.pick" | "snacks" | "telescope" | string
      file_selector = {
        provider = "snacks", -- Avoid native provider issues
        provider_opts = {},
      },
    },
    build = LazyVim.is_win() and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" or "make",
  },
  {
    "saghen/blink.cmp",
    lazy = true,
    dependencies = { "saghen/blink.compat" },
    opts = {
      sources = {
        default = { "avante_commands", "avante_mentions", "avante_files" },
        compat = {
          "avante_commands",
          "avante_mentions",
          "avante_files",
        },
        -- LSP score_offset is typically 60
        providers = {
          avante_commands = {
            name = "avante_commands",
            module = "blink.compat.source",
            score_offset = 90,
            opts = {},
          },
          avante_files = {
            name = "avante_files",
            module = "blink.compat.source",
            score_offset = 100,
            opts = {},
          },
          avante_mentions = {
            name = "avante_mentions",
            module = "blink.compat.source",
            score_offset = 1000,
            opts = {},
          },
        },
      },
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    optional = true,
    ft = function(_, ft)
      vim.list_extend(ft, { "Avante" })
    end,
    opts = function(_, opts)
      opts.file_types = vim.list_extend(opts.file_types or {}, { "Avante" })
    end,
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>a", group = "ai" },
      },
    },
  },
}
