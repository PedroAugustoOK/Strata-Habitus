return {
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        theme              = "tokyonight",
        globalstatus       = true,
        section_separators   = "",
        component_separators = "│",
      },
      sections = {
        lualine_a = { { "mode", fmt = function(s) return s:sub(1,1) end } },
        lualine_b = { { "branch", icon = "" } },
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "diagnostics" },
        lualine_y = { "filetype" },
        lualine_z = { "location" },
      },
    },
  },
  { "akinsho/bufferline.nvim", enabled = false },
  {
    "folke/noice.nvim",
    opts = {
      presets = {
        bottom_search         = true,
        command_palette       = true,
        long_message_to_split = true,
      },
    },
  },
  {
    "nvimdev/dashboard-nvim",
    opts = {
      config = {
        header = {
          "",
          "  ███████╗████████╗██████╗  █████╗ ████████╗ █████╗ ",
          "  ██╔════╝╚══██╔══╝██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗",
          "  ███████╗   ██║   ██████╔╝███████║   ██║   ███████║",
          "  ╚════██║   ██║   ██╔══██╗██╔══██║   ██║   ██╔══██║",
          "  ███████║   ██║   ██║  ██║██║  ██║   ██║   ██║  ██║",
          "  ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝",
          "",
        },
        shortcut = {
          { desc = "󰍉  Buscar",   group = "@property",      action = "Telescope find_files", key = "f" },
          { desc = "   Recentes", group = "Number",          action = "Telescope oldfiles",   key = "r" },
          { desc = "   Plugins",  group = "DiagnosticOk",   action = "Lazy",                 key = "l" },
          { desc = "   Sair",     group = "DiagnosticError", action = "qa",                  key = "q" },
        },
        footer = { "", "  Strata Habitus" },
      },
    },
  },
}
