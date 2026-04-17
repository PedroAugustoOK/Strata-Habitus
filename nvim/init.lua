vim.g.mapleader      = " "
vim.g.maplocalleader = "\\"

-- Suprime aviso falso do LazyVim
local orig = vim.notify
vim.notify = function(msg, ...)
  if msg and msg:find("maplocalleader") then return end
  orig(msg, ...)
end

require("config.lazy")
