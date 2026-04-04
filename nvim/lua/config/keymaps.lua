vim.g.mapleader      = " "
vim.g.maplocalleader = " "
local map = vim.keymap.set
map("n", "<C-s>", "<cmd>w<cr>",   { desc = "Salvar" })
map("n", "<C-q>", "<cmd>q<cr>",   { desc = "Fechar" })
map("n", "<C-h>", "<C-w>h",       { desc = "Split esquerdo" })
map("n", "<C-l>", "<C-w>l",       { desc = "Split direito"  })
map("n", "<C-j>", "<C-w>j",       { desc = "Split abaixo"   })
map("n", "<C-k>", "<C-w>k",       { desc = "Split acima"    })
map("v", "J",     ":m '>+1<cr>gv=gv", { desc = "Mover linha abaixo" })
map("v", "K",     ":m '<-2<cr>gv=gv", { desc = "Mover linha acima"  })
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n",     "nzzzv")
map("n", "N",     "Nzzzv")
map("n", "<Esc>", "<cmd>nohl<cr>", { desc = "Limpar busca" })
map("n", "-",     "<cmd>Oil<cr>",  { desc = "Abrir Oil" })
