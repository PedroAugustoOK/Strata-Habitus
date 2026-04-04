return {
  {
    "stevearc/oil.nvim",
    lazy = false,
    opts = {
      default_file_explorer = true,
      view_options = { show_hidden = true },
      float = {
        padding     = 4,
        border      = "rounded",
        win_options = { winblend = 0 },
      },
      keymaps = {
        ["<CR>"]  = "actions.select",
        ["-"]     = "actions.parent",
        ["q"]     = "actions.close",
        ["<C-p>"] = "actions.preview",
      },
    },
  },
  {
    "nvim-telescope/telescope.nvim",
    opts = {
      defaults = {
        prompt_prefix    = "  ",
        selection_caret  = "  ",
        borderchars      = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
        layout_config    = { prompt_position = "top" },
        sorting_strategy = "ascending",
      },
    },
  },
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add          = { text = "▎" },
        change       = { text = "▎" },
        delete       = { text = "" },
        topdelete    = { text = "" },
        changedelete = { text = "▎" },
      },
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      plugins = { spelling = false },
      win     = { border = "rounded" },
    },
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {
      indent = { char = "│" },
      scope  = { enabled = true },
    },
  },
  { "nvim-mini/mini.pairs",   opts = {} },
  { "nvim-mini/mini.comment", opts = {} },
}
