return {
  "nvim-neo-tree/neo-tree.nvim",
  -- keys = {
  --   {
  --     "<leader>fe",
  --     function()
  --       require("neo-tree.command").execute({
  --         toggle = true,
  --         -- dir = require("lazyvim.util").get_root(),
  --         dir = vim.loop.cwd(),
  --         position = "current",
  --         reveal = true,
  --       })
  --     end,
  --     -- desc = "Explorer NeoTree (root dir)",
  --     desc = "Explorer NeoTree (cwd)",
  --   },
  --   {
  --     "<leader>fE",
  --     function()
  --       require("neo-tree.command").execute({
  --         toggle = true,
  --         -- dir = vim.loop.cwd()
  --         dir = require("lazyvim.util").get_root(),
  --       })
  --     end,
  --     desc = "Explorer NeoTree (root dir)",
  --     -- desc = "Explorer NeoTree (cwd)",
  --   },
  --   { "<leader>e", "<leader>fe", desc = "Explorer NeoTree (root dir)", remap = true },
  --   { "<leader>E", "<leader>fE", desc = "Explorer NeoTree (cwd)", remap = true },
  -- },
  opts = {
    filesystem = {
      filtered_items = {
        visible = true,
        hide_dotfiles = false,
        hide_gitignored = false,
      },
      commands = {
        avante_add_files = function(state)
          local node = state.tree:get_node()
          local filepath = node:get_id()
          local relative_path = require("avante.utils").relative_path(filepath)
          local sidebar = require("avante").get()
          local open = sidebar:is_open()
          -- ensure avante sidebar is open
          if not open then
            require("avante.api").ask()
            sidebar = require("avante").get()
          end
          sidebar.file_selector:add_selected_file(relative_path)
          -- remove neo tree buffer
          if not open then
            sidebar.file_selector:remove_selected_file("neo-tree filesystem [1]")
          end
        end,
      },

      window = {
        -- width = 30,
        mappings = {
          ["oa"] = "avante_add_files",
        },
      },

      bind_to_cwd = false,
      cwd_target = {
        sidebar = "global", -- sidebar is when position = left or right
        current = "none", -- current is when position = current
      },
      find_args = { -- you can specify extra args to pass to the find command.
        fd = {
          "--exclude",
          ".git",
          "--exclude",
          "node_modules",
          "--exclude",
          ".vercel",
        },
      },
    },
  },
}
