local opt = vim.opt
opt.number         = true
opt.relativenumber = false
opt.cursorline     = true
opt.signcolumn     = "yes"
opt.termguicolors  = true
opt.background     = "dark"
opt.showmode       = false
opt.laststatus     = 3
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.api.nvim_set_hl(0, "Normal",      { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalNC",    { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
    vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
    vim.api.nvim_set_hl(0, "SignColumn",  { bg = "none" })
    vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })
  end,
})
opt.tabstop     = 2
opt.shiftwidth  = 2
opt.expandtab   = true
opt.smartindent = true
opt.ignorecase  = true
opt.smartcase   = true
opt.hlsearch    = false
opt.incsearch   = true
opt.scrolloff   = 8
opt.swapfile    = false
opt.undofile    = true
opt.updatetime  = 200
opt.splitright  = true
opt.splitbelow  = true
opt.wrap        = false
opt.clipboard   = "unnamedplus"
opt.confirm     = true
opt.pumheight   = 10
