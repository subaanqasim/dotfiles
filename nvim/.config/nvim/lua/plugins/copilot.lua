return {
  -- {
  --   "zbirenbaum/copilot-cmp",
  --   dependencies = "copilot.lua",
  --   config = function(_, opts)
  --     local copilot_cmp = require("copilot_cmp")
  --
  --     -- opts.fix_pairs = true
  --
  --     copilot_cmp.setup(opts)
  --     -- attach cmp source whenever copilot attaches
  --     -- fixes lazy-loading issues with the copilot cmp source
  --     require("lazyvim.util").lsp.on_attach(function(client)
  --       if client.name == "copilot" then
  --         copilot_cmp._on_insert_enter({})
  --       end
  --     end)
  --   end,
  -- },
}
