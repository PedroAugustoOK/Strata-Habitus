return {
  {
    "folke/tokyonight.nvim",
    lazy     = false,
    priority = 1000,
    opts = {
      style       = "night",
      transparent = true,
      terminal_colors = true,
      styles = {
        comments = { italic = true },
        keywords = { italic = false },
        sidebars = "transparent",
        floats   = "transparent",
      },
      on_highlights = function(hl, c)
        hl.CursorLine   = { bg = "#1a1a2e" }
        hl.Visual       = { bg = "#2a1a3e" }
        hl.Search       = { bg = "#3a2a5e", fg = c.fg }
        hl.IncSearch    = { bg = "#cf9fff", fg = "#0d0d0f" }
        hl.LineNr       = { fg = "#3a3a4e" }
        hl.CursorLineNr = { fg = "#cf9fff" }
      end,
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight")
    end,
  },
  { "LazyVim/LazyVim", opts = { colorscheme = "tokyonight" } },
}
